import 'dart:io';

import 'package:background_fetch/background_fetch.dart' hide NetworkType;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_sync_task.dart';

const String _androidTaskName = 'notificationSyncTask';
const String _androidUniqueName = 'notification-sync-task';

/// Registra la tarea periódica de sincronización de notificaciones.
///
/// En Android usa WorkManager; en iOS usa background_fetch. El callback
/// top-level es el mismo para ambas plataformas.
Future<void> registerBackgroundSync() async {
  if (Platform.isAndroid) {
    await _registerAndroid();
  } else if (Platform.isIOS) {
    await _registerIOS();
  }
}

Future<void> _registerAndroid() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    _androidUniqueName,
    _androidTaskName,
    frequency: const Duration(hours: 12),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

Future<void> _registerIOS() async {
  await BackgroundFetch.configure(
    BackgroundFetchConfig(
      minimumFetchInterval: 15,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
    ),
    notificationSyncTask,
    _onTimeout,
  );
}

/// Callback top-level requerido por WorkManager. Delega en
/// [notificationSyncTask] pasando el nombre de tarea recibido.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    await notificationSyncTask(taskName);
    return true;
  });
}

void _onTimeout(String taskId) {
  debugPrint('[BackgroundSync] iOS timeout taskId=$taskId');
  BackgroundFetch.finish(taskId);
}
