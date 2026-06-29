class AppConstants {
  static const String appName = 'MyAccess IJL';
  static const String appVersion = '1.0.0';

  // Backend Laravel (ajustar según entorno)
  static const String baseUrl = 'http://localhost:8000/api';

  // Hive boxes
  static const String authBox = 'auth_box';
  static const String childrenBox = 'children_box';
  static const String notificationsBox = 'notifications_box';
  static const String settingsBox = 'settings_box';

  // SecureStorage keys
  static const String jwtTokenKey = 'jwt_token';

  // Roles
  static const String roleParent = 'parent';
  static const String roleTeacher = 'teacher';
}
