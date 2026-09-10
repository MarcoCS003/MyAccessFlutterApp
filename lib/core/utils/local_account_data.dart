import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import 'crash_report.dart';
import 'user_key.dart';

/// Borra TODOS los datos locales namespacedos de una cuenta eliminada en el
/// servidor (flujo "Eliminar cuenta", App Store 5.1.1(v)):
/// - `notifications_box['items_<userKey>']` (historial de notificaciones)
/// - `children_box['items_<userKey>']` (hijos cacheados)
/// - `settings_box['lastDiffSync_<userKey>']` (markers de sync v2)
///
/// A diferencia de signOut (que conserva los datos por si la cuenta vuelve),
/// aquí la cuenta fue borrada permanentemente en el backend: nunca volverá
/// a iniciar sesión, así que sus datos locales tampoco deben quedar.
///
/// Best-effort: solo toca la clave de ESA cuenta (nunca box.clear(), que
/// borraría las demás cuentas del dispositivo) y traga errores por clave.
Future<void> deleteLocalDataForAccount(String userKey) async {
  crashLog('delete_local_data: account');
  final key = userStorageKey(userKey);
  final deletions = <String, Future<void>>{
    AppConstants.notificationsBox: Hive.isBoxOpen(AppConstants.notificationsBox)
        ? Hive.box(AppConstants.notificationsBox).delete('items_$key')
        : Future.value(),
    AppConstants.childrenBox: Hive.isBoxOpen(AppConstants.childrenBox)
        ? Hive.box(AppConstants.childrenBox).delete('items_$key')
        : Future.value(),
    AppConstants.settingsBox: Hive.isBoxOpen(AppConstants.settingsBox)
        ? Hive.box(AppConstants.settingsBox).delete('lastDiffSync_$key')
        : Future.value(),
  };
  for (final entry in deletions.entries) {
    try {
      await entry.value;
    } catch (e, st) {
      crashRecordError(e, st);
    }
  }
}
