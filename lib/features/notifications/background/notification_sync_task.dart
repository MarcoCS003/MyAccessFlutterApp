import 'dart:async';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
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
  final jwt = await _readJwt();
  if (jwt == null || jwt.isEmpty) {
    debugPrint('$_tag no JWT found, skipping sync');
    return;
  }

  if (checkPeakHour && _isPeakHour()) {
    debugPrint('$_tag peak hour, skipping sync');
    return;
  }

  final syncService = NotificationSyncService(api: ApiService());
  final notifications = await syncService.fetchPending();
  debugPrint('$_tag fetched ${notifications.length} pending notifications');

  final store = NotificationLocalStore.forCurrentUser();
  for (final notification in notifications) {
    try {
      await store.upsert(notification);
    } catch (e, stackTrace) {
      debugPrint('$_tag upsert error for ${notification.id}: $e\n$stackTrace');
    }
  }

  // ACK best-effort para todas las notificaciones obtenidas que tengan
  // backendId; se hace después de persistir para no perder datos si el
  // inserto falla.
  for (final notification in notifications) {
    final backendId = notification.backendId;
    if (backendId == null) continue;
    unawaited(
      syncService.ack(backendId).catchError((Object e) {
        debugPrint('$_tag ACK error for $backendId: $e');
        return Future<void>.value();
      }),
    );
  }

  await Hive.box(
    AppConstants.settingsBox,
  ).put('lastNotificationSyncAt', DateTime.now().toIso8601String());
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.notificationsBox);
  await Hive.openBox(AppConstants.settingsBox);
}

Future<String?> _readJwt() async {
  try {
    const secureStorage = FlutterSecureStorage();
    return await secureStorage.read(key: AppConstants.jwtTokenKey);
  } catch (e, stackTrace) {
    debugPrint('$_tag error reading JWT: $e\n$stackTrace');
    return null;
  }
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
