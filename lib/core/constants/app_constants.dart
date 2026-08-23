import 'api_config.dart';

class AppConstants {
  static const String appName = 'Acceso IJL';
  static const String appVersion = '1.0.0';

  // Backend Laravel: apunta a ApiConfig para poder alternar entre
  // emulador y dispositivo físico sin tocar el resto de la app.
  static String get baseUrl => ApiConfig.baseUrl;

  // Hive boxes
  static const String authBox = 'auth_box';
  static const String childrenBox = 'children_box';
  static const String notificationsBox = 'notifications_box';
  static const String settingsBox = 'settings_box';

  // SecureStorage keys
  static const String jwtTokenKey = 'jwt_token';

  /// Prefijo para el JWT por cuenta en SecureStorage (multi-sesión):
  /// `jwt_token_<userKey>`. `jwtTokenKey` siempre contiene el de la sesión
  /// activa (ApiService lo lee sin cambios).
  static String jwtKeyFor(String userKey) => 'jwt_token_$userKey';

  /// Clave en auth_box con el mapa de cuentas guardadas:
  /// `userKey → user JSON`.
  static const String authBoxSessionsKey = 'sessions';
}
