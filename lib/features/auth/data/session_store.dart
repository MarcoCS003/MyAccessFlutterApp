import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/user_key.dart';
import '../models/user.dart';

/// Una cuenta guardada en el dispositivo (multi-sesión).
class SavedSession {
  final String userKey;
  final User user;

  const SavedSession({required this.userKey, required this.user});
}

/// CRUD de las sesiones guardadas en el dispositivo.
///
/// Modelo de almacenamiento:
/// - SecureStorage `jwt_token_<userKey>`: JWT de cada cuenta.
/// - SecureStorage `jwt_token`: JWT de la sesión ACTIVA (lo lee ApiService).
/// - auth_box['sessions']: mapa `userKey → user JSON` de todas las cuentas.
/// - auth_box['user']: usuario de la sesión activa (lo usan los handlers FCM).
class SessionStore {
  SessionStore({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  Box get _box => Hive.box(AppConstants.authBox);

  /// Cuentas guardadas, en orden de inserción.
  List<SavedSession> listSessions() {
    final raw =
        _box.get(AppConstants.authBoxSessionsKey) as Map<dynamic, dynamic>?;
    if (raw == null) return [];
    return raw.entries.map((e) {
      final userKey = e.key.toString();
      final userJson = Map<String, dynamic>.from(e.value as Map);
      return SavedSession(userKey: userKey, user: User.fromJson(userJson));
    }).toList();
  }

  /// Agrega o actualiza una sesión y su JWT. No cambia la sesión activa.
  Future<void> saveSession({required User user, required String jwt}) async {
    final userKey = userStorageKey(user.email);
    await _secureStorage.write(
      key: AppConstants.jwtKeyFor(userKey),
      value: jwt,
    );
    final raw =
        (_box.get(AppConstants.authBoxSessionsKey) as Map<dynamic, dynamic>?)
            ?.map((k, v) => MapEntry(k.toString(), v)) ??
        <String, dynamic>{};
    raw[userKey] = user.toJson();
    await _box.put(AppConstants.authBoxSessionsKey, raw);
  }

  Future<String?> getJwt(String userKey) =>
      _secureStorage.read(key: AppConstants.jwtKeyFor(userKey));

  /// Elimina la sesión y su JWT del dispositivo. Los datos namespacedos de
  /// la cuenta (notificaciones, hijos cacheados) se conservan por si vuelve
  /// a iniciar sesión.
  Future<void> removeSession(String userKey) async {
    await _secureStorage.delete(key: AppConstants.jwtKeyFor(userKey));
    final raw =
        (_box.get(AppConstants.authBoxSessionsKey) as Map<dynamic, dynamic>?)
            ?.map((k, v) => MapEntry(k.toString(), v)) ??
        <String, dynamic>{};
    raw.remove(userKey);
    await _box.put(AppConstants.authBoxSessionsKey, raw);
  }

  /// Deja [userKey] como sesión activa: copia su JWT a `jwt_token` y su
  /// usuario a auth_box['user']. Devuelve false si la sesión no existe o
  /// no tiene JWT guardado.
  Future<bool> setActive(String userKey) async {
    SavedSession? session;
    for (final s in listSessions()) {
      if (s.userKey == userKey) {
        session = s;
        break;
      }
    }
    if (session == null) return false;
    final jwt = await getJwt(userKey);
    if (jwt == null || jwt.isEmpty) return false;
    await _secureStorage.write(key: AppConstants.jwtTokenKey, value: jwt);
    await _box.put('user', session.user.toJson());
    return true;
  }

  /// Limpia la sesión activa (sin eliminar cuentas guardadas).
  Future<void> clearActive() async {
    await _secureStorage.delete(key: AppConstants.jwtTokenKey);
    await _box.delete('user');
  }
}
