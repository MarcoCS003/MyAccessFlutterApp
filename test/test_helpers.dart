import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

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
