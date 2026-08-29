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

const String _tag = '[BackgroundSync]';

enum NotificationAccountSyncStatus {
  success,
  missingToken,
  networkError,
  unauthorized,
  parseError,
  serverError,
  persistenceError,
  ackError,
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

  bool get succeeded => status == NotificationAccountSyncStatus.success;
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
/// Inicializa Hive, valida JWT y horario pico, descarga las notificaciones
/// pendientes, las persiste localmente y confirma recepción al backend de
/// forma durable. Nunca propaga excepciones para evitar crashes en background.
@pragma('vm:entry-point')
Future<void> notificationSyncTask(String taskId) async {
  try {
    debugPrint('$_tag starting taskId=$taskId');

    await _initHive();
    await _executeSync(checkPeakHour: true);

    debugPrint('$_tag completed successfully');
  } catch (e, stackTrace) {
    debugPrint('$_tag unhandled error: $e\n$stackTrace');
  } finally {
    await _finishTask(taskId);
  }
}

/// Sync de respaldo al abrir la app.
///
/// No reinicializa Hive porque en foreground ya está lista. Solo ejecuta el
/// sync si la última sincronización fue hace más de 12 horas. No aplica el
/// filtro de horario pico porque el usuario ya está usando la app.
Future<void> maybeSyncOnAppOpen() async {
  try {
    if (!_shouldSyncOnOpen()) {
      debugPrint('$_tag app open sync skipped, last sync too recent');
      return;
    }
    debugPrint('$_tag app open sync triggered');
    await _executeSync(checkPeakHour: false);
  } catch (e, stackTrace) {
    debugPrint('$_tag app open sync error: $e\n$stackTrace');
  }
}

bool _shouldSyncOnOpen() {
  final sessions = SessionStore().listSessions();
  if (sessions.isEmpty) return false;
  final settings = Hive.box(AppConstants.settingsBox);
  return sessions.any((session) {
    final lastSyncRaw = settings.get(_syncMarkerKey(session.userKey));
    if (lastSyncRaw is! String) return true;
    final lastSync = DateTime.tryParse(lastSyncRaw);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours >= 12;
  });
}

Future<NotificationSyncRunResult> _executeSync({
  required bool checkPeakHour,
  SessionStore? sessionStore,
  NotificationSyncServiceFactory? serviceFactory,
}) async {
  if (checkPeakHour && _isPeakHour()) {
    debugPrint('$_tag peak hour, skipping sync');
    return const NotificationSyncRunResult({});
  }

  final store = sessionStore ?? SessionStore();
  final sessions = store.listSessions();
  if (sessions.isEmpty) {
    debugPrint('$_tag no saved sessions, skipping sync');
    return const NotificationSyncRunResult({});
  }

  final results = <String, NotificationAccountSyncResult>{};
  // Multi-sesión: cada cuenta guardada se sincroniza con su PROPIO JWT, así
  // los inboxes de todas las cuentas se mantienen al día aunque no sean la
  // sesión activa. Un fallo en una cuenta se loggea y no detiene a las demás.
  for (final session in sessions) {
    try {
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
      if (result.succeeded) {
        try {
          await Hive.box(AppConstants.settingsBox).put(
            _syncMarkerKey(session.userKey),
            DateTime.now().toIso8601String(),
          );
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

/// Ejecuta inmediatamente el sync de todas las cuentas guardadas. Está
/// expuesto para QA y pruebas, sin depender de WorkManager/background_fetch.
Future<NotificationSyncRunResult> syncNow({
  SessionStore? sessionStore,
  NotificationSyncServiceFactory? serviceFactory,
}) => _executeSync(
  checkPeakHour: false,
  sessionStore: sessionStore,
  serviceFactory: serviceFactory,
);

/// Sincroniza las notificaciones pendientes de UNA cuenta.
///
/// El endpoint `/notifications/sync` devuelve las pendientes del dueño del
/// JWT usado, así que todo se guarda en el inbox de [session]. Si un item
/// trae `user_id` y no coincide con la cuenta (inconsistencia del backend),
/// se descarta y NO se hace ACK de él. Expuesta para pruebas unitarias.
Future<NotificationAccountSyncResult> syncAccountNotifications({
  required SavedSession session,
  required NotificationSyncService syncService,
}) async {
  var status = NotificationAccountSyncStatus.success;
  var ackFailed = false;
  var persistenceFailed = false;
  final retriedAckIds = <int>{};

  final pendingAcks = _loadPendingAcks(session.userKey);
  for (final backendId in pendingAcks) {
    retriedAckIds.add(backendId);
    if (!await ackNotificationForAccount(
      userKey: session.userKey,
      backendId: backendId,
      syncService: syncService,
    )) {
      ackFailed = true;
    }
  }

  final fetchResult = await syncService.fetchPending();
  if (fetchResult.failure != null) {
    status = _statusForFailure(fetchResult.failure!);
  }
  final notifications = fetchResult.notifications;
  debugPrint(
    '$_tag fetched ${notifications.length} pending for ${session.userKey}',
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

      final backendId = notification.backendId;
      if (backendId != null && !retriedAckIds.contains(backendId)) {
        final acked = await ackNotificationForAccount(
          userKey: session.userKey,
          backendId: backendId,
          syncService: syncService,
        );
        if (!acked) ackFailed = true;
      }
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
  if (ackFailed) {
    status = NotificationAccountSyncStatus.ackError;
  }
  return NotificationAccountSyncResult(
    status: status,
    fetchedCount: notifications.length,
    insertedCount: insertedCount,
  );
}

/// Envía un ACK con el servicio autenticado de la cuenta propietaria. Si
/// falla, conserva el id en settings para reintentarlo en el siguiente sync.
Future<bool> ackNotificationForAccount({
  required String userKey,
  required int backendId,
  required NotificationSyncService syncService,
}) async {
  final result = await syncService.ack(backendId);
  final pending = _loadPendingAcks(userKey);
  if (result.succeeded) {
    pending.remove(backendId);
    await _savePendingAcks(userKey, pending);
    return true;
  }

  if (!pending.contains(backendId)) pending.add(backendId);
  await _savePendingAcks(userKey, pending);
  return false;
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

String _syncMarkerKey(String userKey) =>
    'lastNotificationSyncAt_${userStorageKey(userKey)}';

String _ackQueueKey(String userKey) =>
    'pendingNotificationAcks_${userStorageKey(userKey)}';

List<int> _loadPendingAcks(String userKey) {
  try {
    final raw = Hive.box(AppConstants.settingsBox).get(_ackQueueKey(userKey));
    if (raw is! List) return [];
    return raw
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .toSet()
        .toList();
  } catch (e, st) {
    debugPrint('$_tag could not load ACK queue: $e');
    crashRecordError(e, st);
    return [];
  }
}

Future<bool> _savePendingAcks(String userKey, List<int> ids) async {
  try {
    await Hive.box(AppConstants.settingsBox).put(_ackQueueKey(userKey), ids);
    return true;
  } catch (e, st) {
    debugPrint('$_tag could not save ACK queue: $e');
    crashRecordError(e, st);
    return false;
  }
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.childrenBox);
  await Hive.openBox(AppConstants.notificationsBox);
  await Hive.openBox(AppConstants.settingsBox);
}

/// Horario pico: 7:00–9:00 y 13:00–15:00 hora local.
///
/// Se usan intervalos semi-abiertos [inicio, fin) para alinear los límites
/// exactos con el final del horario pico.
bool _isPeakHour() {
  final now = DateTime.now();
  final hour = now.hour;
  return (hour >= 7 && hour < 9) || (hour >= 13 && hour < 15);
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
