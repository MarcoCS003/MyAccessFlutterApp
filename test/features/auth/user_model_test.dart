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

  group('User.teacher (relación con teachers)', () {
    test('fromJson con teacher poblado', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Maestra',
        'email': 'm@ijl.mx',
        'role': 'teacher',
        'teacher': {'id': 109, 'qr_code': 'DEMO-TEACHER-001'},
      });
      expect(user.teacher, isNotNull);
      expect(user.teacher!.id, 109);
      expect(user.teacher!.qrCode, 'DEMO-TEACHER-001');
    });

    test('fromJson con teacher null (parent o sin vínculo)', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Marco',
        'email': 'm@ijl.mx',
        'role': 'parent',
        'teacher': null,
      });
      expect(user.teacher, isNull);
    });

    test('fromJson sin la key (sesión cacheada vieja) → teacher null', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Maestra',
        'email': 'm@ijl.mx',
        'role': 'teacher',
      });
      expect(user.teacher, isNull);
    });

    test('fromJson con teacher y qr_code null → teacher.qrCode null', () {
      final user = User.fromJson(const {
        'id': 1,
        'name': 'Maestra',
        'email': 'm@ijl.mx',
        'role': 'teacher',
        'teacher': {'id': 109, 'qr_code': null},
      });
      expect(user.teacher, isNotNull);
      expect(user.teacher!.id, 109);
      expect(user.teacher!.qrCode, isNull);
    });

    test('toJson/fromJson round-trip conserva teacher', () {
      const user = User(
        id: 1,
        name: 'Maestra',
        email: 'm@ijl.mx',
        role: 'teacher',
        teacher: UserTeacher(id: 109, qrCode: 'DEMO-TEACHER-001'),
      );
      final roundTrip = User.fromJson(user.toJson());
      expect(roundTrip.teacher, isNotNull);
      expect(roundTrip.teacher!.id, 109);
      expect(roundTrip.teacher!.qrCode, 'DEMO-TEACHER-001');
    });

    test('copyWith reemplaza teacher', () {
      const user = User(
        id: 1,
        name: 'Maestra',
        email: 'm@ijl.mx',
        role: 'teacher',
        teacher: UserTeacher(id: 109, qrCode: 'OLD'),
      );
      final updated = user.copyWith(
        teacher: const UserTeacher(id: 209, qrCode: 'NEW'),
      );
      expect(updated.teacher!.id, 209);
      expect(updated.teacher!.qrCode, 'NEW');
    });

    test('copyWith con clearTeacher:true pone teacher null', () {
      const user = User(
        id: 1,
        name: 'Maestra',
        email: 'm@ijl.mx',
        role: 'teacher',
        teacher: UserTeacher(id: 109, qrCode: 'OLD'),
      );
      final cleared = user.copyWith(clearTeacher: true);
      expect(cleared.teacher, isNull);
    });
  });
}