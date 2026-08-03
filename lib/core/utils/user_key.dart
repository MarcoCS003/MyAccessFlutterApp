/// Aislamiento multi-usuario de la BD local: cada cuenta (identificada por
/// su email, el mismo criterio del seeder demo) tiene sus propias claves
/// dentro de los boxes Hive (`items_<userKey>`), así dos cuentas en el
/// mismo dispositivo no comparten datos.
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// userKey de respaldo para mensajes FCM que llegan sin sesión guardada:
/// se persisten en un inbox global fijo (`items__anonymous`) que la UI
/// nunca lee, pero así el mensaje no se pierde.
const String anonymousUserKey = '_anonymous';

/// Normaliza un email como clave de storage. Hive acepta '@' y '.' en las
/// claves, así que basta con recortar y unificar mayúsculas.
String userStorageKey(String email) => email.trim().toLowerCase();

/// userKey de la última sesión persistida en auth_box, o null si no hay
/// ninguna. Pensado para código fuera del árbol de providers (handlers FCM,
/// background isolate), donde no hay ref para leer authProvider.
///
/// Ojo: signOut borra el JWT pero conserva auth_box['user'], así que tras
/// un logout los mensajes que sigan llegando se guardan bajo la última
/// cuenta conocida del dispositivo (es a quien pertenecen).
String? currentUserKey() {
  if (!Hive.isBoxOpen(AppConstants.authBox)) return null;
  final data =
      Hive.box(AppConstants.authBox).get('user') as Map<dynamic, dynamic>?;
  final email = data?['email'];
  return email is String && email.isNotEmpty ? userStorageKey(email) : null;
}
