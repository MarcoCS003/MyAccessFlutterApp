import 'dart:io';

import 'package:background_fetch/background_fetch.dart' hide NetworkType;
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_sync_task.dart';
import 'sync_window.dart';

const String _androidTaskName = 'notificationSyncTask';
const String _androidUniqueName = 'notification-sync-task';

/// Programa la próxima sincronización de notificaciones (sync v2).
///
/// En Android registra un one-off de WorkManager con `initialDelay` hasta el
/// inicio de la próxima ventana (9:00 o 15:00 local) y
/// `ExistingWorkPolicy.replace`, así siempre hay exactamente una tarea
/// pendiente; la propia tarea se reagenda al terminar. En iOS se configura
/// `background_fetch` (intervalo aproximado del SO) y la ventana se valida
/// dentro de la tarea.
Future<void> scheduleNextSyncWindow({DateTime? now}) async {
  if (Platform.isAndroid) {
    await Workmanager().initialize(callbackDispatcher);
    await scheduleAndroidOneOff(nextWindowStart(now ?? DateTime.now()));
  } else if (Platform.isIOS) {
    await _registerIOS();
  }
}

/// Registra el one-off de Android para ejecutarse en [at] (inicio de ventana
/// o slot del dispositivo). Accesible desde la tarea en background para
/// reagendar sin repetir `initialize`.
Future<void> scheduleAndroidOneOff(DateTime at) async {
  final delay = at.difference(DateTime.now());
  await Workmanager().registerOneOffTask(
    _androidUniqueName,
    _androidTaskName,
    initialDelay: delay.isNegative ? Duration.zero : delay,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingWorkPolicy.replace,
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
