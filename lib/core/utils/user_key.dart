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

/// Resuelve a qué inbox (`items_<userKey>`) pertenece una notificación
/// entrante cuando el dispositivo tiene varias sesiones guardadas.
///
/// Ruteo determinístico: si el payload trae [recipientUserId] (`user_id`,
/// agregado por el backend), se busca la sesión cuyo `user.id` coincida.
/// Si ese usuario no tiene sesión en el dispositivo se devuelve **null**:
/// la notificación se DESCARTA (no se guarda, no se muestra bandeja, no
/// se hace ACK) — es de un usuario que no está en este dispositivo.
///
/// Ruteo legado (payloads sin `user_id`, anteriores al cambio de backend):
/// - `teacher_attendance` → la cuenta guardada con rol teacher. Si no hay
///   ninguna (cuenta eliminada y token aún vivo en backend), cae al inbox
///   anónimo: NUNCA al inbox de un papá.
/// - `student_attendance` → la cuenta cuyos hijos cacheados en children_box
///   contengan [studentId]; si no hay match pero existe una sola cuenta con
///   rol parent, se le asigna a ella (su caché puede estar vacío).
/// - Sin forma de determinarlo → sesión activa; sin sesiones → anónimo.
///
/// Pensado para handlers FCM y el isolate de background (sin providers).
String? resolveUserKeyForNotification({
  int? recipientUserId,
  required String type,
  required int studentId,
}) {
  final sessions = _savedSessions();

  if (recipientUserId != null) {
    for (final entry in sessions.entries) {
      if (entry.value['id'] == recipientUserId) return entry.key;
    }
    return null;
  }

  if (type == 'teacher_attendance') {
    for (final entry in sessions.entries) {
      if (entry.value['role'] == 'teacher') return entry.key;
    }
    return anonymousUserKey;
  }

  if (studentId != 0) {
    for (final userKey in sessions.keys) {
      if (_childrenCacheContains(userKey, studentId)) return userKey;
    }
  }

  final parentKeys = sessions.entries
      .where((e) => e.value['role'] == 'parent')
      .map((e) => e.key)
      .toList();
  if (parentKeys.length == 1) return parentKeys.single;

  final active = currentUserKey();
  if (active != null && sessions[active]?['role'] == 'parent') return active;
  return active ?? anonymousUserKey;
}

/// Mapa `userKey → user JSON` de las cuentas guardadas (vacío si no hay).
Map<String, Map<String, dynamic>> _savedSessions() {
  if (!Hive.isBoxOpen(AppConstants.authBox)) return {};
  final raw =
      Hive.box(AppConstants.authBox).get(AppConstants.authBoxSessionsKey)
          as Map<dynamic, dynamic>?;
  if (raw == null) return {};
  return raw.map(
    (k, v) => MapEntry(k.toString(), Map<String, dynamic>.from(v as Map)),
  );
}

bool _childrenCacheContains(String userKey, int studentId) {
  if (!Hive.isBoxOpen(AppConstants.childrenBox)) return false;
  final raw = Hive.box(AppConstants.childrenBox).get('items_$userKey') as List?;
  if (raw == null) return false;
  for (final e in raw) {
    if (e is Map && e['id'] == studentId) return true;
  }
  return false;
}
