import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/features/profile/models/app_settings.dart';
import 'package:cliente_flutter_myaccess/features/profile/providers/profile_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('ProfileNotifier', () {
    test('toggleNotifications persiste en Hive', () async {
      final notifier = ProfileNotifier();
      // Esperar a que terminen las cargas iniciales.
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.toggleNotifications(false);

      expect(notifier.state.settings.notificationsEnabled, isFalse);

      final box = Hive.box('settings_box');
      final saved = box.get('app_settings') as Map<dynamic, dynamic>;
      expect(saved['notificationsEnabled'], isFalse);
    });

    test('setThemeMode persiste en Hive', () async {
      final notifier = ProfileNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      await notifier.setThemeMode(ThemeMode.dark);

      expect(notifier.state.settings.themeMode, ThemeMode.dark);

      final box = Hive.box('settings_box');
      final saved = box.get('app_settings') as Map<dynamic, dynamic>;
      expect(saved['themeMode'], ThemeMode.dark.index);
    });

    test('carga preferencias guardadas previamente', () async {
      final box = Hive.box('settings_box');
      await box.put(
        'app_settings',
        const AppSettings(
          notificationsEnabled: false,
          themeMode: ThemeMode.light,
        ).toJson(),
      );

      final notifier = ProfileNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.settings.notificationsEnabled, isFalse);
      expect(notifier.state.settings.themeMode, ThemeMode.light);
    });

    test('version cae en fallback cuando PackageInfo falla', () async {
      final notifier = ProfileNotifier();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.version, isNotNull);
      expect(notifier.state.version!.startsWith('v'), isTrue);
    });
  });
}
