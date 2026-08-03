import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/notifications/providers/notification_provider.dart';

import 'mocks/auth_mocks.dart';
import 'test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeTestHive();
    // La pantalla formatea encabezados de fecha con DateFormat locale 'es'.
    await initializeDateFormatting('es');
  });

  testWidgets('HomeMaestroScreen renderiza header, stats y filtros', (
    tester,
  ) async {
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
          notificationProvider.overrideWith((ref) => NotificationNotifier()),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeMaestroScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MAESTRO'), findsOneWidget);
    expect(find.text('Resumen de notificaciones'), findsOneWidget);
    expect(find.text('Notificaciones de hoy'), findsOneWidget);
    expect(find.text('Mes'), findsOneWidget);
  });
}
