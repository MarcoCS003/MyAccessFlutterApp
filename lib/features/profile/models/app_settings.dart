/// Preferencias de la aplicación persistidas localmente en Hive.
class AppSettings {
  final bool notificationsEnabled;

  const AppSettings({this.notificationsEnabled = true});

  AppSettings copyWith({bool? notificationsEnabled}) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {'notificationsEnabled': notificationsEnabled};
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
    );
  }
}
