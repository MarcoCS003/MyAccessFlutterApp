import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider used only by the debug role toggle button.
/// When null, the real user role from authProvider is used.
/// When set, it overrides the UI role so both parent and teacher
/// home screens can be previewed without re-login.
final debugRoleProvider = StateProvider<String?>((ref) => null);
