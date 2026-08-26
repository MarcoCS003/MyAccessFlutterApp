import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cliente_flutter_myaccess/core/constants/app_constants.dart';
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

  setUp(() {
    // Aísla cada test: las sesiones guardadas viven en auth_box['sessions'].
    // clear() es síncrono en memoria; el flush a disco ocurre en background.
    Hive.box(AppConstants.authBox).clear();
  });

  const parentUser = User(
    id: 1,
    name: 'Juan Perez',
    email: 'juan@ijl.mx',
    role: 'parent',
  );
  const teacherUser = User(
    id: 2,
    name: 'Maria Lopez',
    email: 'maria@ijl.mx',
    role: 'teacher',
  );

  Widget buildProfile(User user) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          (ref) => MockAuthNotifier(
            AuthState(status: AuthStatus.authenticated, user: user),
          ),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );
  }

  /// Escribe sesiones en auth_box SIN await: en testWidgets la zona es
  /// FakeAsync y el flush a disco de Hive (I/O real) nunca completa, lo que
  /// congela el test. El put se aplica en memoria de inmediato y las
  /// lecturas (`box.get`) son síncronas, así que no hace falta esperarlo.
  void seedSessions(List<User> users) {
    Hive.box(AppConstants.authBox).put(AppConstants.authBoxSessionsKey, {
      for (final u in users) u.email.trim().toLowerCase(): u.toJson(),
    });
  }

  testWidgets('ProfileScreen renderiza detalles del usuario', (tester) async {
    await tester.pumpWidget(buildProfile(parentUser));
    await tester.pumpAndSettle();
    expect(find.text('Configuración'), findsOneWidget);
    expect(find.text('Juan Perez'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('Tutor con 1 cuenta no ve la sección Cuentas ni Agregar cuenta', (
    tester,
  ) async {
    seedSessions([parentUser]);
    await tester.pumpWidget(buildProfile(parentUser));
    await tester.pumpAndSettle();
    expect(find.text('Cuentas'), findsNothing);
    expect(find.text('Agregar cuenta'), findsNothing);
  });

  testWidgets(
    'Tutor con 2 cuentas puede cambiar entre ellas pero no agregar',
    (tester) async {
      seedSessions([parentUser, teacherUser]);
      await tester.pumpWidget(buildProfile(parentUser));
      await tester.pumpAndSettle();
      expect(find.text('Cuentas'), findsOneWidget);
      expect(find.text('Juan Perez'), findsWidgets);
      expect(find.text('Maria Lopez'), findsOneWidget);
      expect(find.text('Agregar cuenta'), findsNothing);
    },
  );

  testWidgets('Docente ve el botón Agregar cuenta', (tester) async {
    seedSessions([teacherUser]);
    await tester.pumpWidget(buildProfile(teacherUser));
    await tester.pumpAndSettle();
    expect(find.text('Cuentas'), findsOneWidget);
    expect(find.text('Agregar cuenta'), findsOneWidget);
  });
}
