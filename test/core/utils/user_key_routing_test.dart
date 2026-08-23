import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cliente_flutter_myaccess/core/constants/app_constants.dart';
import 'package:cliente_flutter_myaccess/core/utils/user_key.dart';

import '../../test_helpers.dart';

void main() {
  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  Future<void> saveSession(String email, String role, {int id = 1}) async {
    final raw =
        (Hive.box(AppConstants.authBox).get(AppConstants.authBoxSessionsKey)
                as Map<dynamic, dynamic>?)
            ?.map((k, v) => MapEntry(k.toString(), v)) ??
        <String, dynamic>{};
    raw[userStorageKey(email)] = {
      'id': id,
      'name': email,
      'email': email,
      'role': role,
    };
    await Hive.box(
      AppConstants.authBox,
    ).put(AppConstants.authBoxSessionsKey, raw);
  }

  Future<void> cacheChildren(String email, List<int> ids) async {
    await Hive.box(AppConstants.childrenBox).put(
      'items_${userStorageKey(email)}',
      ids
          .map(
            (id) => {
              'id': id,
              'name': 'Alumno $id',
              'codigo': 'C$id',
              'grado': '1',
              'grupo': 'A',
            },
          )
          .toList(),
    );
  }

  group('resolveUserKeyForNotification', () {
    test('teacher_attendance va a la cuenta con rol teacher', () async {
      await saveSession('papa@ijl.edu.mx', 'parent');
      await saveSession('maestra@ijl.edu.mx', 'teacher');

      final key = resolveUserKeyForNotification(
        type: 'teacher_attendance',
        studentId: 0,
      );

      expect(key, 'maestra@ijl.edu.mx');
    });

    test(
      'teacher_attendance sin cuenta teacher cae al inbox anónimo',
      () async {
        await saveSession('papa@ijl.edu.mx', 'parent');

        final key = resolveUserKeyForNotification(
          type: 'teacher_attendance',
          studentId: 0,
        );

        expect(key, anonymousUserKey);
      },
    );

    test(
      'student_attendance va a la cuenta cuyo caché contiene al alumno',
      () async {
        await saveSession('papa@ijl.edu.mx', 'parent');
        await saveSession('otro@ijl.edu.mx', 'parent');
        await cacheChildren('otro@ijl.edu.mx', [7, 8]);

        final key = resolveUserKeyForNotification(
          type: 'student_attendance',
          studentId: 7,
        );

        expect(key, 'otro@ijl.edu.mx');
      },
    );

    test('sin match de caché y un solo papá, va a ese papá', () async {
      await saveSession('papa@ijl.edu.mx', 'parent');
      await saveSession('maestra@ijl.edu.mx', 'teacher');

      final key = resolveUserKeyForNotification(
        type: 'student_attendance',
        studentId: 99,
      );

      expect(key, 'papa@ijl.edu.mx');
    });

    test('sin sesiones cae al inbox anónimo', () {
      final key = resolveUserKeyForNotification(
        type: 'student_attendance',
        studentId: 1,
      );

      expect(key, anonymousUserKey);
    });

    test('con varios papás sin match de caché usa la sesión activa', () async {
      await saveSession('papa1@ijl.edu.mx', 'parent');
      await saveSession('papa2@ijl.edu.mx', 'parent');
      await Hive.box(AppConstants.authBox).put('user', {
        'id': 1,
        'name': 'Papá 2',
        'email': 'papa2@ijl.edu.mx',
        'role': 'parent',
      });

      final key = resolveUserKeyForNotification(
        type: 'student_attendance',
        studentId: 99,
      );

      expect(key, 'papa2@ijl.edu.mx');
    });
  });

  group('resolveUserKeyForNotification con user_id', () {
    test('va a la sesión cuyo user.id coincide con el user_id', () async {
      await saveSession('papa@ijl.edu.mx', 'parent', id: 10);
      await saveSession('maestra@ijl.edu.mx', 'teacher', id: 20);

      final key = resolveUserKeyForNotification(
        recipientUserId: 20,
        type: 'teacher_attendance',
        studentId: 0,
      );

      expect(key, 'maestra@ijl.edu.mx');
    });

    test(
      'user_id sin sesión en el dispositivo devuelve null (descartar)',
      () async {
        await saveSession('papa@ijl.edu.mx', 'parent', id: 10);

        final key = resolveUserKeyForNotification(
          recipientUserId: 99,
          type: 'teacher_attendance',
          studentId: 0,
        );

        expect(key, isNull);
      },
    );

    test('user_id tiene prioridad sobre el ruteo por contenido', () async {
      await saveSession('papa@ijl.edu.mx', 'parent', id: 10);
      await saveSession('maestra@ijl.edu.mx', 'teacher', id: 20);

      // El tipo dice teacher_attendance pero el destinatario es el papá:
      // manda el user_id.
      final key = resolveUserKeyForNotification(
        recipientUserId: 10,
        type: 'teacher_attendance',
        studentId: 0,
      );

      expect(key, 'papa@ijl.edu.mx');
    });

    test('sin sesiones guardadas y con user_id devuelve null', () {
      final key = resolveUserKeyForNotification(
        recipientUserId: 10,
        type: 'student_attendance',
        studentId: 5,
      );

      expect(key, isNull);
    });
  });
}
