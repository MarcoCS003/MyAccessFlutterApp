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
}
