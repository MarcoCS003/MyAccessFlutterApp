import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/features/maestros/providers/teacher_provider.dart';

import '../../mocks/auth_mocks.dart';

void main() {
  ProviderContainer buildContainer(AuthState authState) {
    return ProviderContainer(
      overrides: [
        authProvider.overrideWith((ref) => MockAuthNotifier(authState)),
      ],
    );
  }

  group('teacherQrProvider', () {
    test('sin sesión autenticada → null', () {
      final container = buildContainer(const AuthState());
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });

    test('usuario parent → null (no consulta teacher)', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: 1, name: 'Padre', email: 'p@ijl.mx', role: 'parent'),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });

    test('teacher sin user.teacher → null', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: 1,
            name: 'Maestra',
            email: 'm@ijl.mx',
            role: 'teacher',
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });

    test('teacher con teacher.qrCode poblado → devuelve el código', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: 1,
            name: 'Maestra',
            email: 'm@ijl.mx',
            role: 'teacher',
            teacher: UserTeacher(id: 109, qrCode: 'DEMO-TEACHER-001'),
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), 'DEMO-TEACHER-001');
    });

    test('teacher con teacher.qrCode vacío → null', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: 1,
            name: 'Maestra',
            email: 'm@ijl.mx',
            role: 'teacher',
            teacher: UserTeacher(id: 109, qrCode: ''),
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });

    test('teacher con teacher.qrCode solo whitespace → null', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: 1,
            name: 'Maestra',
            email: 'm@ijl.mx',
            role: 'teacher',
            teacher: UserTeacher(id: 109, qrCode: '   '),
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });

    test('teacher con teacher.qrCode con padding → trim antes de devolver', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: 1,
            name: 'Maestra',
            email: 'm@ijl.mx',
            role: 'teacher',
            teacher: UserTeacher(id: 109, qrCode: '  ABC  '),
          ),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), 'ABC');
    });

    test('admin sin teacher → null', () {
      final container = buildContainer(
        const AuthState(
          status: AuthStatus.authenticated,
          user: User(id: 1, name: 'Admin', email: 'a@ijl.mx', role: 'admin'),
        ),
      );
      addTearDown(container.dispose);

      expect(container.read(teacherQrProvider), isNull);
    });
  });
}