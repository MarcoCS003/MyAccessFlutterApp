import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/crash_report.dart';
import '../../../core/utils/user_key.dart';
import '../../auth/data/session_store.dart';
import '../../../services/api_service.dart';
import '../data/notification_local_store.dart';
import '../data/notification_sync_service.dart';
import 'background_sync_register.dart';
import 'sync_window.dart';

const String _tag = '[BackgroundSync]';

/// Cuántos IDs locales se envían al diff (el backend compara contra sus
/// últimos 10 registros de la cuenta).
const int diffWindowSize = 10;

enum NotificationAccountSyncStatus {
  success,
  alreadySynced,
  missingToken,
  networkError,
  unauthorized,
  parseError,
  serverError,
  persistenceError,
}

class NotificationAccountSyncResult {
  const NotificationAccountSyncResult({
    required this.status,
    this.fetchedCount = 0,
    this.insertedCount = 0,
  });

  final NotificationAccountSyncStatus status;
  final int fetchedCount;
  final int insertedCount;

  bool get succeeded =>
      status == NotificationAccountSyncStatus.success ||
      status == NotificationAccountSyncStatus.alreadySynced;
}

class NotificationSyncRunResult {
  const NotificationSyncRunResult(this.accounts);

  final Map<String, NotificationAccountSyncResult> accounts;

  bool get succeeded =>
      accounts.isNotEmpty &&
      accounts.values.every((result) => result.succeeded);
}

typedef NotificationSyncServiceFactory =
    NotificationSyncService Function(SavedSession session, String jwt);

/// Callback ejecutado por WorkManager (Android) y background_fetch (iOS).
///
/// Sync v2 (FCM como cartero): solo corre en las ventanas despejadas
/// 9:00–10:00 y 15:00–16:00, en el slot aleatorio del dispositivo, y pide al
/// backend los registros faltantes (diff de IDs). Nunca propaga excepciones
/// para evitar crashes en background.
@pragma('vm:entry-point')
Future<void> notificationSyncTask(String taskId) async {
  try {
    debugPrint('$_tag starting taskId=$taskId');

    await _initHive();
    final now = DateTime.now();
    final windowStart = activeWindowStart(now);
    if (windowStart == null) {
      // Fuera de ventana + grace: solo reagendar la siguiente ventana.
      debugPrint('$_tag fuera de ventana, se reagenda');
      await _scheduleNextWindowSafely(now);
      return;
    }

    final store = SessionStore();
    final sessions = store.listSessions();
    final slot = await resolveDeviceSyncSlot(sessions);
    final slotTime = windowStart.add(Duration(seconds: slot));
    if (now.isBefore(slotTime)) {
      // Aún no llega el slot del dispositivo. WorkManager limita la tarea a
      // ~10 min, así que no se espera dentro: se reagenda al slot exacto
      // (Android). En iOS background_fetch volverá a disparar la tarea.
      debugPrint('$_tag slot no alcanzado (slot a las $slotTime)');
      if (Platform.isAndroid) {
        await _scheduleOneOffAtSafely(slotTime);
      }
      return;
    }

    await _executeSync(windowStart: windowStart, sessionStore: store);

    // Pase lo que pase, reagendar la siguiente ventana.
    await _scheduleNextWindowSafely(DateTime.now());
    debugPrint('$_tag completed successfully');
  } catch (e, stackTrace) {
    debugPrint('$_tag unhandled error: $e\n$stackTrace');
  } finally {
    await _finishTask(taskId);
  }
}

/// Sync de respaldo al abrir la app.
///
/// Solo corre si ya inició una ventana (la actual o la última pasada) y
/// alguna cuenta no tiene el marcador de esa ventana: el auto-sync de
/// background no la cubrió (Doze, iOS sin fetch, app recién instalada).
Future<void> maybeSyncOnAppOpen() async {
  try {
    if (!_missedCurrentWindow()) {
      debugPrint('$_tag app open sync skipped, ventana ya cubierta');
      return;
    }
    debugPrint('$_tag app open sync triggered (ventana sin marcador)');
    await _executeSync(windowStart: activeWindowStart(DateTime.now()));
  } catch (e, stackTrace) {
    debugPrint('$_tag app open sync error: $e\n$stackTrace');
  }
}

bool _missedCurrentWindow() {
  final sessions = SessionStore().listSessions();
  if (sessions.isEmpty) return false;
  final marker = windowMarkerValue(lastStartedWindow(DateTime.now()));
  final settings = Hive.box(AppConstants.settingsBox);
  return sessions.any(
    (session) => settings.get(_diffMarkerKey(session.userKey)) != marker,
  );
}

Future<NotificationSyncRunResult> _executeSync({
  required DateTime? windowStart,
  SessionStore? sessionStore,
  NotificationSyncServiceFactory? serviceFactory,
}) async {
  final store = sessionStore ?? SessionStore();
  final sessions = store.listSessions();
  if (sessions.isEmpty) {
    debugPrint('$_tag no saved sessions, skipping sync');
    return const NotificationSyncRunResult({});
  }

  final marker = windowStart == null ? null : windowMarkerValue(windowStart);
  final results = <String, NotificationAccountSyncResult>{};
  // Multi-sesión: cada cuenta guardada se sincroniza con su PROPIO JWT, así
  // los inboxes de todas las cuentas se mantienen al día aunque no sean la
  // sesión activa. Un fallo en una cuenta se loggea y no detiene a las demás.
  for (final session in sessions) {
    try {
      if (marker != null &&
          Hive.box(AppConstants.settingsBox).get(
                _diffMarkerKey(session.userKey),
              ) ==
              marker) {
        debugPrint('$_tag $marker ya sincronizada para esta cuenta, skip');
        results[session.userKey] = const NotificationAccountSyncResult(
          status: NotificationAccountSyncStatus.alreadySynced,
        );
        continue;
      }

      final jwt = await store.getJwt(session.userKey);
      if (jwt == null || jwt.isEmpty) {
        debugPrint('$_tag account has no JWT, skipping account');
        results[session.userKey] = const NotificationAccountSyncResult(
          status: NotificationAccountSyncStatus.missingToken,
        );
        continue;
      }

      final syncService =
          serviceFactory?.call(session, jwt) ??
          NotificationSyncService(api: ApiService(authToken: jwt));
      final result = await syncAccountNotifications(
        session: session,
        syncService: syncService,
      );
      results[session.userKey] = result;
      // El marcador solo se escribe si la cuenta sincronizó bien: un fallo
      // (red/401/parseo) deja la ventana pendiente y se reintenta después.
      if (result.succeeded && marker != null) {
        try {
          await Hive.box(
            AppConstants.settingsBox,
          ).put(_diffMarkerKey(session.userKey), marker);
        } catch (e, st) {
          crashRecordError(e, st);
          results[session.userKey] = const NotificationAccountSyncResult(
            status: NotificationAccountSyncStatus.persistenceError,
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('$_tag sync error for account: $e\n$stackTrace');
      crashRecordError(e, stackTrace);
      results[session.userKey] = const NotificationAccountSyncResult(
        status: NotificationAccountSyncStatus.networkError,
      );
    }
  }

  return NotificationSyncRunResult(results);
}

/// Ejecuta inmediatamente el diff de todas las cuentas guardadas. Está
/// expuesto para QA y pruebas (pull-to-refresh), sin chequeos de ventana ni
/// slot; si la app se abre dentro de una ventana, marca esa ventana.
Future<NotificationSyncRunResult> syncNow({
  SessionStore? sessionStore,
  NotificationSyncServiceFactory? serviceFactory,
}) => _executeSync(
  windowStart: activeWindowStart(DateTime.now()),
  sessionStore: sessionStore,
  serviceFactory: serviceFactory,
);

/// Variante con ventana explícita, expuesta para pruebas unitarias.
@visibleForTesting
Future<NotificationSyncRunResult> executeWindowSync({
  required DateTime windowStart,
  SessionStore? sessionStore,
  NotificationSyncServiceFactory? serviceFactory,
}) => _executeSync(
  windowStart: windowStart,
  sessionStore: sessionStore,
  serviceFactory: serviceFactory,
);

/// Sincroniza las notificaciones faltantes de UNA cuenta vía diff.
///
/// Se envían los últimos [diffWindowSize] `backendId` locales de
/// `items_<userKey>` y el backend responde solo los registros que faltan,
/// que se guardan en el inbox de [session]. Si un item trae `user_id` y no
/// coincide con la cuenta (inconsistencia del backend), se descarta.
/// Expuesta para pruebas unitarias.
Future<NotificationAccountSyncResult> syncAccountNotifications({
  required SavedSession session,
  required NotificationSyncService syncService,
}) async {
  var status = NotificationAccountSyncStatus.success;
  var persistenceFailed = false;

  final localIds = _recentLocalBackendIds(session.userKey);
  final fetchResult = await syncService.fetchDiff(localIds);
  if (fetchResult.failure != null) {
    status = _statusForFailure(fetchResult.failure!);
  }
  final notifications = fetchResult.notifications;
  debugPrint(
    '$_tag diff devolvió ${notifications.length} faltantes para '
    '${session.userKey} (localIds=$localIds)',
  );

  final store = NotificationLocalStore(userKey: session.userKey);
  var insertedCount = 0;
  for (final notification in notifications) {
    try {
      final recipientId = notification.recipientUserId;
      if (recipientId != null && recipientId != session.user.id) {
        debugPrint(
          '$_tag item ${notification.id} es de user $recipientId, '
          'se descarta en el sync de ${session.userKey}',
        );
        continue;
      }
      final persistence = await store.upsert(notification);
      if (!persistence.persisted) {
        persistenceFailed = true;
        continue;
      }
      if (persistence.inserted) insertedCount++;
    } catch (e, stackTrace) {
      debugPrint('$_tag upsert error for ${notification.id}: $e\n$stackTrace');
      crashRecordError(e, stackTrace);
      persistenceFailed = true;
    }
  }
  crashLog('notif_sync: inserted=$insertedCount');

  if (persistenceFailed) {
    status = NotificationAccountSyncStatus.persistenceError;
  }
  return NotificationAccountSyncResult(
    status: status,
    fetchedCount: notifications.length,
    insertedCount: insertedCount,
  );
}

/// Los últimos [diffWindowSize] `backendId` guardados en el inbox local de
/// la cuenta, de más reciente a más antiguo. Items sin `backendId` (llegados
/// por FCM sin `notification_id`) no participan en el diff.
List<int> _recentLocalBackendIds(String userKey) {
  try {
    final ids =
        NotificationLocalStore(userKey: userKey)
            .load()
            .map((n) => n.backendId)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    return ids.take(diffWindowSize).toList();
  } catch (e, st) {
    debugPrint('$_tag could not load local ids: $e');
    crashRecordError(e, st);
    return [];
  }
}

NotificationAccountSyncStatus _statusForFailure(
  NotificationSyncFailure failure,
) {
  switch (failure.kind) {
    case NotificationSyncFailureKind.network:
      return NotificationAccountSyncStatus.networkError;
    case NotificationSyncFailureKind.unauthorized:
      return NotificationAccountSyncStatus.unauthorized;
    case NotificationSyncFailureKind.parse:
      return NotificationAccountSyncStatus.parseError;
    case NotificationSyncFailureKind.server:
      return NotificationAccountSyncStatus.serverError;
  }
}

String _diffMarkerKey(String userKey) =>
    'lastDiffSync_${userStorageKey(userKey)}';

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.childrenBox);
  await Hive.openBox(AppConstants.notificationsBox);
  await Hive.openBox(AppConstants.settingsBox);
}

Future<void> _scheduleNextWindowSafely(DateTime now) async {
  try {
    await scheduleNextSyncWindow(now: now);
  } catch (e, stackTrace) {
    debugPrint('$_tag error reagendando siguiente ventana: $e\n$stackTrace');
    crashRecordError(e, stackTrace);
  }
}

Future<void> _scheduleOneOffAtSafely(DateTime at) async {
  try {
    await scheduleAndroidOneOff(at);
  } catch (e, stackTrace) {
    debugPrint('$_tag error reagendando al slot: $e\n$stackTrace');
    crashRecordError(e, stackTrace);
  }
}

Future<void> _finishTask(String taskId) async {
  if (Platform.isIOS) {
    try {
      BackgroundFetch.finish(taskId);
    } catch (e, stackTrace) {
      debugPrint('$_tag error finishing iOS task: $e\n$stackTrace');
    }
  }
}
