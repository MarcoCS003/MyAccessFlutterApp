import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../models/app_settings.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);

class ProfileState {
  final AppSettings settings;
  final String? version;
  final bool isLoading;

  const ProfileState({
    this.settings = const AppSettings(),
    this.version,
    this.isLoading = false,
  });

  ProfileState copyWith({
    AppSettings? settings,
    String? version,
    bool? isLoading,
  }) {
    return ProfileState(
      settings: settings ?? this.settings,
      version: version ?? this.version,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState()) {
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadSettings() async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final json = box.get('app_settings') as Map<dynamic, dynamic>?;
      if (json != null) {
        state = state.copyWith(
          settings: AppSettings.fromJson(Map<String, dynamic>.from(json)),
        );
      }
    } catch (e) {
      debugPrint('Error loading app settings from Hive: $e');
    }
  }

  Future<void> _saveSettings(AppSettings settings) async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      await box.put('app_settings', settings.toJson());
      state = state.copyWith(settings: settings);
    } catch (e) {
      debugPrint('Error saving app settings to Hive: $e');
    }
  }

  Future<void> toggleNotifications(bool enabled) async {
    final newSettings = state.settings.copyWith(notificationsEnabled: enabled);
    await _saveSettings(newSettings);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final newSettings = state.settings.copyWith(themeMode: mode);
    await _saveSettings(newSettings);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      state = state.copyWith(
        version: 'v${info.version} (build ${info.buildNumber})',
      );
    } catch (e) {
      debugPrint('Error loading package info: $e');
      state = state.copyWith(version: 'v1.0.0');
    }
  }
}
