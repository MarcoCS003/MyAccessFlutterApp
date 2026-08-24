import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Acceso best-effort a Crashlytics.
///
/// Todas las funciones tragan cualquier error: la app (y los tests, donde
/// Firebase no está inicializado) deben funcionar aunque Crashlytics no
/// esté disponible.
///
/// Regla de cumplimiento: NUNCA loggear PII (email, nombre, student_id,
/// tokens, códigos de vinculación) — solo IDs internos y eventos.
void crashLog(String message) {
  try {
    unawaited(FirebaseCrashlytics.instance.log(message));
  } catch (_) {}
}

void crashRecordError(Object error, StackTrace stackTrace) {
  try {
    unawaited(FirebaseCrashlytics.instance.recordError(error, stackTrace));
  } catch (_) {}
}

/// Identifica al usuario con su ID interno (`user_<id>`), nunca con email
/// ni nombre. Con `''` se limpia la identificación (logout).
Future<void> crashSetUser(String userId) async {
  try {
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  } catch (_) {}
}

Future<void> crashSetRole(String role) async {
  try {
    await FirebaseCrashlytics.instance.setCustomKey('role', role);
  } catch (_) {}
}
