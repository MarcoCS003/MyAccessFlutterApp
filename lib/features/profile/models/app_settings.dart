import 'package:flutter/material.dart';

/// Preferencias de la aplicación persistidas localmente en Hive.
class AppSettings {
  final bool notificationsEnabled;
  final ThemeMode themeMode;

  const AppSettings({
    this.notificationsEnabled = true,
    this.themeMode = ThemeMode.system,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'themeMode': themeMode.index,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      themeMode: ThemeMode
          .values[(json['themeMode'] ?? 0) as int],
    );
  }
}
