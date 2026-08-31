import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

void main() {
  group('User.mustChangePassword', () {
    test('fromJson sin la key (sesiones cacheadas viejas) → false', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Maestra',
        'email': 'm@ijl.mx',
        'role': 'teacher',
      });
      expect(user.mustChangePassword, isFalse);
    });

    test('fromJson con must_change_password en true', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Maestra',
        'email': 'm@ijl.mx',
        'role': 'teacher',
        'must_change_password': true,
      });
      expect(user.mustChangePassword, isTrue);
    });

    test('toJson/fromJson conservan el flag', () {
      const user = User(
        id: 1,
        name: 'Maestra',
        email: 'm@ijl.mx',
        role: 'teacher',
        mustChangePassword: true,
      );
      final roundTrip = User.fromJson(user.toJson());
      expect(roundTrip.mustChangePassword, isTrue);
    });

    test('copyWith apaga el flag', () {
      const user = User(
        id: 1,
        name: 'Maestra',
        email: 'm@ijl.mx',
        role: 'teacher',
        mustChangePassword: true,
      );
      expect(
        user.copyWith(mustChangePassword: false).mustChangePassword,
        isFalse,
      );
    });
  });

  group('User ruteo por rol (lista blanca)', () {
    User withRole(String role) =>
        User(id: 1, name: 'N', email: 'e@ijl.mx', role: role);

    test('parent → isParent, no isTeacher', () {
      final user = withRole('parent');
      expect(user.isParent, isTrue);
      expect(user.isTeacher, isFalse);
    });

    test('teacher/admin/root → isTeacher', () {
      for (final role in ['teacher', 'admin', 'root']) {
        expect(withRole(role).isTeacher, isTrue, reason: role);
        expect(withRole(role).isParent, isFalse, reason: role);
      }
    });

    test('student/user se ignoran (ni parent ni teacher)', () {
      for (final role in ['student', 'user']) {
        expect(withRole(role).isTeacher, isFalse, reason: role);
        expect(withRole(role).isParent, isFalse, reason: role);
      }
    });
  });
}
