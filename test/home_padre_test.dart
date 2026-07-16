import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/home_padre_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

import 'mocks/auth_mocks.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('HomePadreScreen renderiza lista de estudiantes', (tester) async {
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
          emptyChildrenProviderOverride,
        ],
        child: const MaterialApp(home: Scaffold(body: HomePadreScreen())),
      ),
    );
    expect(find.text('Tus hijos vinculados'), findsOneWidget);
  });
}
