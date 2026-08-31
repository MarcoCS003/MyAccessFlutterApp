import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/core/router/router.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/auth/screens/change_password_screen.dart';
import 'package:cliente_flutter_myaccess/features/auth/screens/login_screen.dart';
import 'package:cliente_flutter_myaccess/features/home/screens/main_navigation_screen.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/home_padre_screen.dart';

import '../../mocks/auth_mocks.dart';
import '../../test_helpers.dart';
import '../../main_navigation_test.dart' show MockHttpOverrides;

AuthState authWith(User user) =>
    AuthState(status: AuthStatus.authenticated, user: user);

User userWithRole(String role, {bool mustChangePassword = false}) => User(
  id: 1,
  name: 'Test',
  email: 'test@ijl.mx',
  role: role,
  mustChangePassword: mustChangePassword,
);

Widget appWithRouter(AuthState authState) {
  return ProviderScope(
    overrides: [
      authProvider.overrideWith((ref) => MockAuthNotifier(authState)),
      emptyChildrenProviderOverride,
    ],
    child: Consumer(
      builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(routerConfig: router);
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    HttpOverrides.global = MockHttpOverrides();
    await initializeTestHive();
  });

  group('Ruteo por rol (lista blanca) en MainNavigationScreen', () {
    for (final role in ['teacher', 'admin', 'root']) {
      testWidgets('rol $role muestra HomeMaestroScreen', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authProvider.overrideWith(
                (ref) => MockAuthNotifier(authWith(userWithRole(role))),
              ),
              emptyChildrenProviderOverride,
            ],
            child: const MaterialApp(home: MainNavigationScreen()),
          ),
        );
        expect(find.byType(HomeMaestroScreen), findsOneWidget);
        expect(find.byType(HomePadreScreen), findsNothing);
      });
    }
  });

  group('Guard de cambio de contraseña forzado', () {
    testWidgets('usuario con mustChangePassword cae en /change-password', (
      tester,
    ) async {
      await tester.pumpWidget(
        appWithRouter(
          authWith(userWithRole('teacher', mustChangePassword: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsOneWidget);
    });

    testWidgets('usuario sin flag sigue el flujo normal (login → home)', (
      tester,
    ) async {
      await tester.pumpWidget(appWithRouter(authWith(userWithRole('teacher'))));
      await tester.pumpAndSettle();
      expect(find.byType(ChangePasswordScreen), findsNothing);
      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(MainNavigationScreen), findsOneWidget);
    });

    testWidgets('sin autenticar cae en login', (tester) async {
      await tester.pumpWidget(
        appWithRouter(const AuthState(status: AuthStatus.unauthenticated)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
