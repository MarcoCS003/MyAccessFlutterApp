import 'package:cliente_flutter_myaccess/features/notifications/data/notification_local_store.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_seeder.dart';
import 'package:cliente_flutter_myaccess/features/notifications/models/notification_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers.dart';

void main() {
  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  const people = [(id: 10, name: 'Pedro Pérez'), (id: 11, name: 'Ana López')];

  test(
    'genera solo lunes-viernes, entrada y salida por día, sin futuros',
    () async {
      final seeder = NotificationSeeder();
      final count = await seeder.seedMonthForUser(
        userKey: 'padre@ijl.edu.mx',
        people: people,
        type: 'student_attendance',
      );

      final items = NotificationLocalStore(userKey: 'padre@ijl.edu.mx').load();
      expect(count, greaterThan(0));
      expect(items.length, count);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final byDay = <String, List<NotificationItem>>{};

      for (final item in items) {
        expect(item.timestamp.isAfter(now), isFalse);
        expect(item.timestamp.weekday, lessThanOrEqualTo(DateTime.friday));
        expect(item.location, NotificationSeeder.demoLocation);
        expect(item.isRead, isTrue);
        expect(item.type, 'student_attendance');
        final day = DateTime(
          item.timestamp.year,
          item.timestamp.month,
          item.timestamp.day,
        );
        final key = '${item.studentId}_${day.toIso8601String()}';
        byDay.putIfAbsent(key, () => []).add(item);
      }

      for (final group in byDay.values) {
        final ts = group.first.timestamp;
        final day = DateTime(ts.year, ts.month, ts.day);
        // Hoy puede tener solo la entrada si aún no es hora de salida.
        if (day == today) continue;
        expect(group.length, 2);
        final entrada = group.firstWhere((e) => e.event == 'check_in');
        final salida = group.firstWhere((e) => e.event == 'check_out');
        expect(entrada.timestamp.hour, lessThan(9));
        expect(salida.timestamp.hour, greaterThanOrEqualTo(13));
      }
    },
  );

  test('es idempotente por usuario y conserva notificaciones reales', () async {
    await NotificationLocalStore(userKey: 'padre@ijl.edu.mx').upsert(
      NotificationItem(
        id: 'real-1',
        type: 'student_attendance',
        event: 'check_in',
        studentName: 'Alumno Real',
        studentId: 99,
        timestamp: DateTime.now(),
      ),
    );

    final seeder = NotificationSeeder();
    final first = await seeder.seedMonthForUser(
      userKey: 'padre@ijl.edu.mx',
      people: people,
      type: 'student_attendance',
    );
    expect(first, greaterThan(0));
    final totalAfterFirst = NotificationLocalStore(
      userKey: 'padre@ijl.edu.mx',
    ).load().length;

    // Mismo usuario: no duplica.
    final second = await seeder.seedMonthForUser(
      userKey: 'padre@ijl.edu.mx',
      people: people,
      type: 'student_attendance',
    );
    expect(second, 0);
    expect(
      NotificationLocalStore(userKey: 'padre@ijl.edu.mx').load().length,
      totalAfterFirst,
    );

    // Otro usuario: siembra su propia tanda, aislada en su clave.
    final other = await seeder.seedMonthForUser(
      userKey: 'maestro@ijl.edu.mx',
      people: const [(id: 20, name: 'Marco Carrasco')],
      type: 'teacher_attendance',
    );
    expect(other, greaterThan(0));

    // El padre conserva lo suyo (incluida la notificación real) y NO ve
    // lo sembrado para el maestro.
    final padreItems = NotificationLocalStore(
      userKey: 'padre@ijl.edu.mx',
    ).load();
    expect(padreItems.any((n) => n.id == 'real-1'), isTrue);
    expect(padreItems.length, totalAfterFirst);
    expect(padreItems.any((n) => n.studentId == 20), isFalse);

    // El maestro solo tiene su tanda, sin datos del padre.
    final maestroItems = NotificationLocalStore(
      userKey: 'maestro@ijl.edu.mx',
    ).load();
    expect(maestroItems.length, other);
    expect(maestroItems.any((n) => n.id == 'real-1'), isFalse);
    expect(
      maestroItems.firstWhere((n) => n.studentId == 20).type,
      'teacher_attendance',
    );
  });
}
