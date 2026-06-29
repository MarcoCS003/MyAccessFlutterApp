import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

import 'mocks/auth_mocks.dart';

void main() {
  testWidgets('HomeMaestroScreen renderiza estadísticas y QR', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => MockAuthNotifier(
              AuthState(
                status: AuthStatus.authenticated,
                user: User(
                  id: 2,
                  name: 'Prof. Carlos Ortega',
                  email: 'carlos@ijl.mx',
                  role: 'teacher',
                ),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HomeMaestroScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Historial de hoy'), findsOneWidget);
  });
}
