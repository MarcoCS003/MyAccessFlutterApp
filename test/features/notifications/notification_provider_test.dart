import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_local_store.dart';
import 'package:cliente_flutter_myaccess/features/notifications/models/notification_item.dart';
import 'package:cliente_flutter_myaccess/features/notifications/providers/notification_provider.dart';

import '../../test_helpers.dart';

void main() {
  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('NotificationNotifier', () {
    test('agregar notificación desde FCM la guarda en Hive', () async {
      final notifier = NotificationNotifier();
      await notifier.addFromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });

      expect(notifier.state.length, 1);
      expect(notifier.state.first.studentName, 'Juan Pérez');
      expect(notifier.state.first.event, 'check_in');
      expect(notifier.unreadCount, 1);
    });

    test('marcar como leída reduce unreadCount', () async {
      final notifier = NotificationNotifier();
      await notifier.addFromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });
      await notifier.addFromFcm({
        'student_id': '2',
        'student_name': 'Ana López',
        'event': 'check_out',
        'timestamp': '2026-06-29T09:00:00.000Z',
        'type': 'attendance',
      });

      final idToRead = notifier.state.first.id;
      await notifier.markAsRead(idToRead);

      expect(notifier.unreadCount, 1);
      expect(notifier.state.firstWhere((n) => n.id == idToRead).isRead, isTrue);
    });

    test('marcar todo como leído deja unreadCount en 0', () async {
      final notifier = NotificationNotifier();
      await notifier.addFromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });
      await notifier.addFromFcm({
        'student_id': '2',
        'student_name': 'Ana López',
        'event': 'check_out',
        'timestamp': '2026-06-29T09:00:00.000Z',
        'type': 'attendance',
      });

      await notifier.markAllAsRead();

      expect(notifier.unreadCount, 0);
      expect(notifier.state.every((n) => n.isRead), isTrue);
    });

    test('dismiss elimina la notificación', () async {
      final notifier = NotificationNotifier();
      await notifier.addFromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });
      final id = notifier.state.first.id;

      await notifier.dismiss(id);

      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.unreadCount, 0);
    });

    test('clearAll vacía todas las notificaciones', () async {
      final notifier = NotificationNotifier();
      await notifier.addFromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      });

      await notifier.clearAll();

      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.unreadCount, 0);
    });

    test('addFromFcm con el mismo id solo se guarda una vez', () async {
      final notifier = NotificationNotifier();
      final data = {
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': '2026-06-29T08:00:00.000Z',
        'type': 'attendance',
      };
      await notifier.addFromFcm(data);
      final isDuplicated = await notifier.addFromFcm(data);

      expect(notifier.state.length, 1);
      expect(isDuplicated, isFalse);
    });

    test('reloadFromLocal recupera items escritos directo en Hive', () async {
      // Simula al handler de background escribiendo desde otro isolate.
      final store = NotificationLocalStore();
      await store.upsert(
        NotificationItem.fromFcm({
          'student_id': '1',
          'student_name': 'Juan Pérez',
          'event': 'check_in',
          'timestamp': '2026-06-29T08:00:00.000Z',
        }),
      );

      final notifier = NotificationNotifier(); // el constructor recarga Hive
      expect(notifier.state.length, 1);
      expect(notifier.state.first.studentName, 'Juan Pérez');
    });

    test(
      'addFromFcm no pierde items escritos por el handler de background',
      () async {
        final notifier = NotificationNotifier();
        await NotificationLocalStore().upsert(
          NotificationItem.fromFcm({
            'student_id': '1',
            'student_name': 'Juan Pérez',
            'event': 'check_in',
            'timestamp': '2026-06-29T08:00:00.000Z',
          }),
        );

        await notifier.addFromFcm({
          'student_id': '2',
          'student_name': 'Ana López',
          'event': 'check_out',
          'timestamp': '2026-06-29T09:00:00.000Z',
          'type': 'attendance',
        });

        expect(notifier.state.length, 2); // merge: no se pierde el del bg
      },
    );

    test('fromFcm convierte timestamp UTC (Z) a hora local', () {
      final item = NotificationItem.fromFcm({
        'student_id': '1',
        'student_name': 'Juan Pérez',
        'event': 'check_in',
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });

      expect(item.timestamp.isUtc, isFalse);
      final now = DateTime.now();
      expect(item.timestamp.year, now.year);
      expect(item.timestamp.month, now.month);
      expect(item.timestamp.day, now.day);
    });
  });
}
