import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:cliente_flutter_myaccess/features/padres/models/child.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';

/// Initializes Hive in a temporary directory and opens the boxes used by the app.
/// Call this in setUpAll() of widget tests that depend on providers
/// accessing Hive (auth, notifications, children, settings).
Future<void> initializeTestHive() async {
  final tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(tempDir.path);
  await Hive.openBox('auth_box');
  await Hive.openBox('children_box');
  await Hive.openBox('notifications_box');
  await Hive.openBox('settings_box');
}

/// Deletes all Hive boxes and closes the instance. Use in tearDown() of unit
/// tests that write to Hive to keep each test isolated.
Future<void> cleanUpTestHive() async {
  await Hive.deleteBoxFromDisk('auth_box');
  await Hive.deleteBoxFromDisk('children_box');
  await Hive.deleteBoxFromDisk('notifications_box');
  await Hive.deleteBoxFromDisk('settings_box');
}

/// Notificador de prueba que no realiza peticiones de red.
class _NoOpChildrenNotifier extends ChildrenNotifier {
  _NoOpChildrenNotifier() : super() {
    state = const AsyncValue<List<Child>>.data([]);
  }

  @override
  Future<void> initialize() async {
    // No hace nada: evita llamadas de red en widget tests.
  }
}

/// Override para [childrenProvider] que evita llamadas de red en widget tests.
/// El notificador inicia con una lista vacía de hijos.
final emptyChildrenProviderOverride = childrenProvider.overrideWith(
  (ref) => _NoOpChildrenNotifier(),
);
