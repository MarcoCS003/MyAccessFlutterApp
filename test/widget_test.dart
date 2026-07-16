import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cliente_flutter_myaccess/features/auth/screens/login_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';

import 'mocks/auth_mocks.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => MockAuthNotifier(const AuthState()),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.text('Instituto Juárez Lincoln'), findsOneWidget);
    expect(find.text('Control de Acceso Escolar'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(
      find.text('Inicia sesión para recibir notificaciones de acceso.'),
      findsOneWidget,
    );
    expect(find.text('Regístrate'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
