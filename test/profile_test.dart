import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/profile/screens/profile_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

import 'mocks/auth_mocks.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeTestHive();
  });

  testWidgets('ProfileScreen renderiza detalles del usuario', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => MockAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: User(
                  id: 1,
                  name: 'Juan Perez',
                  email: 'juan@ijl.mx',
                  role: 'parent',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Juan Perez'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });
}
