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

  const userKey = 'padre@ijl.edu.mx';

  group('NotificationNotifier', () {
    test('agregar notificación desde FCM la guarda en Hive', () async {
      final notifier = NotificationNotifier(userKey: userKey);
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
      final notifier = NotificationNotifier(userKey: userKey);
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
      final notifier = NotificationNotifier(userKey: userKey);
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
      final notifier = NotificationNotifier(userKey: userKey);
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
      final notifier = NotificationNotifier(userKey: userKey);
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
      final notifier = NotificationNotifier(userKey: userKey);
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
      final store = NotificationLocalStore(userKey: userKey);
      await store.upsert(
        NotificationItem.fromFcm({
          'student_id': '1',
          'student_name': 'Juan Pérez',
          'event': 'check_in',
          'timestamp': '2026-06-29T08:00:00.000Z',
        }),
      );

      final notifier = NotificationNotifier(
        userKey: userKey,
      ); // el constructor recarga Hive
      expect(notifier.state.length, 1);
      expect(notifier.state.first.studentName, 'Juan Pérez');
    });

    test(
      'reloadFromLocal relee el box desde disco tras una escritura externa',
      () async {
        // El notifier ya existe (cargó 0 items); una escritura posterior
        // directa al box (como la del isolate de background) debe reflejarse
        // al recargar.
        final notifier = NotificationNotifier(userKey: userKey);
        expect(notifier.state, isEmpty);

        await NotificationLocalStore(userKey: userKey).upsert(
          NotificationItem.fromFcm({
            'student_id': '1',
            'student_name': 'Juan Pérez',
            'event': 'check_in',
            'timestamp': '2026-06-29T08:00:00.000Z',
          }),
        );

        await notifier.reloadFromLocal();

        expect(notifier.state.length, 1);
        expect(notifier.state.first.studentName, 'Juan Pérez');
      },
    );

    test(
      'addFromFcm no pierde items escritos por el handler de background',
      () async {
        final notifier = NotificationNotifier(userKey: userKey);
        await NotificationLocalStore(userKey: userKey).upsert(
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

  group('aislamiento multi-usuario', () {
    const keyA = 'a@ijl.edu.mx';
    const keyB = 'b@ijl.edu.mx';

    Map<String, dynamic> fcm(String studentId, String name) => {
      'student_id': studentId,
      'student_name': name,
      'event': 'check_in',
      'timestamp': '2026-06-29T08:00:00.000Z',
      'type': 'attendance',
    };

    test('lo escrito con el userKey A no se lee con el userKey B', () async {
      final notifierA = NotificationNotifier(userKey: keyA);
      await notifierA.addFromFcm(fcm('1', 'Hijo de A'));

      // B no ve nada de A, ni en memoria ni directo en Hive.
      final notifierB = NotificationNotifier(userKey: keyB);
      expect(notifierB.state, isEmpty);
      expect(NotificationLocalStore(userKey: keyB).load(), isEmpty);

      // Y viceversa: lo que escribe B no contamina a A.
      await notifierB.addFromFcm(fcm('2', 'Hijo de B'));
      expect(NotificationLocalStore(userKey: keyA).load().length, 1);
      expect(
        NotificationLocalStore(userKey: keyA).load().first.studentName,
        'Hijo de A',
      );
      expect(NotificationLocalStore(userKey: keyB).load().length, 1);
    });

    test(
      'sin sesión los FCM caen en el inbox anónimo que la UI no lee',
      () async {
        // Simula el background handler sin usuario guardado en auth_box.
        await NotificationLocalStore.forCurrentUser().upsert(
          NotificationItem.fromFcm(fcm('9', 'Sin sesión')),
        );

        // Un notifier autenticado no lee ese inbox.
        final notifier = NotificationNotifier(userKey: keyA);
        expect(notifier.state, isEmpty);
        // Pero el mensaje quedó persistido bajo la clave anónima.
        expect(NotificationLocalStore(userKey: '_anonymous').load().length, 1);
      },
    );
  });
}
