import 'dart:async';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/data/session_store.dart';
import '../../../services/api_service.dart';
import '../data/notification_local_store.dart';
import '../data/notification_sync_service.dart';

const String _tag = '[BackgroundSync]';

/// Callback ejecutado por WorkManager (Android) y background_fetch (iOS).
///
/// Inicializa Hive, valida JWT y horario pico, descarga las notificaciones
/// pendientes, las persiste localmente y confirma recepción al backend de
/// forma best-effort. Nunca propaga excepciones para evitar crashes en
/// background.
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
  final lastSyncRaw =
      Hive.box(AppConstants.settingsBox).get('lastNotificationSyncAt')
          as String?;
  if (lastSyncRaw == null) return true;
  final lastSync = DateTime.tryParse(lastSyncRaw);
  if (lastSync == null) return true;
  return DateTime.now().difference(lastSync).inHours >= 12;
}

Future<void> _executeSync({required bool checkPeakHour}) async {
  if (checkPeakHour && _isPeakHour()) {
    debugPrint('$_tag peak hour, skipping sync');
    return;
  }

  final sessionStore = SessionStore();
  final sessions = sessionStore.listSessions();
  if (sessions.isEmpty) {
    debugPrint('$_tag no saved sessions, skipping sync');
    return;
  }

  // Multi-sesión: cada cuenta guardada se sincroniza con su PROPIO JWT, así
  // los inboxes de todas las cuentas se mantienen al día aunque no sean la
  // sesión activa. Un fallo en una cuenta se loggea y no detiene a las demás.
  for (final session in sessions) {
    try {
      final jwt = await sessionStore.getJwt(session.userKey);
      if (jwt == null || jwt.isEmpty) {
        debugPrint('$_tag no JWT for ${session.userKey}, skipping account');
        continue;
      }
      await syncAccountNotifications(
        session: session,
        syncService: NotificationSyncService(api: ApiService(authToken: jwt)),
      );
    } catch (e, stackTrace) {
      debugPrint('$_tag sync error for ${session.userKey}: $e\n$stackTrace');
    }
  }

  await Hive.box(
    AppConstants.settingsBox,
  ).put('lastNotificationSyncAt', DateTime.now().toIso8601String());
}

/// Sincroniza las notificaciones pendientes de UNA cuenta.
///
/// El endpoint `/notifications/sync` devuelve las pendientes del dueño del
/// JWT usado, así que todo se guarda en el inbox de [session]. Si un item
/// trae `user_id` y no coincide con la cuenta (inconsistencia del backend),
/// se descarta y NO se hace ACK de él. Expuesta para pruebas unitarias.
Future<void> syncAccountNotifications({
  required SavedSession session,
  required NotificationSyncService syncService,
}) async {
  final notifications = await syncService.fetchPending();
  debugPrint(
    '$_tag fetched ${notifications.length} pending for ${session.userKey}',
  );

  final store = NotificationLocalStore(userKey: session.userKey);
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
      await store.upsert(notification);

      // ACK best-effort después de persistir, con el JWT de esta cuenta.
      final backendId = notification.backendId;
      if (backendId != null) {
        unawaited(
          syncService.ack(backendId).catchError((Object e) {
            debugPrint('$_tag ACK error for $backendId: $e');
            return Future<void>.value();
          }),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('$_tag upsert error for ${notification.id}: $e\n$stackTrace');
    }
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
