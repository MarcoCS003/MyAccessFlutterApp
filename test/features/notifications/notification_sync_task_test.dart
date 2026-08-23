import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/notifications/background/notification_sync_task.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_local_store.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_sync_service.dart';
import 'package:cliente_flutter_myaccess/features/notifications/models/notification_item.dart';

import '../../test_helpers.dart';

/// Sync service de prueba: devuelve una lista fija y registra los ACKs.
class _FakeSyncService extends NotificationSyncService {
  _FakeSyncService(this.pending);

  final List<NotificationItem> pending;
  final List<int> acked = [];

  @override
  Future<List<NotificationItem>> fetchPending() async => pending;

  @override
  Future<void> ack(int backendId) async {
    acked.add(backendId);
  }
}

NotificationItem _item(String id, {int? backendId, int? recipientUserId}) {
  return NotificationItem(
    id: id,
    backendId: backendId,
    recipientUserId: recipientUserId,
    type: 'student_attendance',
    event: 'check_in',
    studentName: 'Alumno $id',
    studentId: 1,
    timestamp: DateTime(2026, 8, 20, 7, 30),
  );
}

SavedSession _session(String email, int id, String role) => SavedSession(
  userKey: email,
  user: User(id: id, name: email, email: email, role: role),
);

void main() {
  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('syncAccountNotifications', () {
    test('guarda las pendientes en el inbox de la cuenta y hace ACK', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([
        _item('a', backendId: 100, recipientUserId: 10),
        _item('b', backendId: 101), // sin user_id: pertenece al dueño del JWT
      ]);

      await syncAccountNotifications(session: session, syncService: service);
      // Los ACKs son unawaited: dejar correr los microtasks.
      await Future<void>.delayed(Duration.zero);

      final saved = NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load();
      expect(saved.map((n) => n.id), containsAll(['a', 'b']));
      expect(service.acked, containsAll([100, 101]));
    });

    test(
      'descarta items con user_id de otra cuenta y no les hace ACK',
      () async {
        final session = _session('papa@ijl.edu.mx', 10, 'parent');
        final service = _FakeSyncService([
          _item('propia', backendId: 100, recipientUserId: 10),
          _item('ajena', backendId: 200, recipientUserId: 20),
        ]);

        await syncAccountNotifications(session: session, syncService: service);
        await Future<void>.delayed(Duration.zero);

        final saved = NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load();
        expect(saved.map((n) => n.id), ['propia']);
        expect(service.acked, [100]);
      },
    );

    test('no escribe nada en el inbox de otra cuenta', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([_item('a', backendId: 100)]);

      await syncAccountNotifications(session: session, syncService: service);
      await Future<void>.delayed(Duration.zero);

      final otherInbox = NotificationLocalStore(
        userKey: 'maestra@ijl.edu.mx',
      ).load();
      expect(otherInbox, isEmpty);
    });

    test('una cuenta maestra sincroniza su propio inbox', () async {
      final session = _session('maestra@ijl.edu.mx', 20, 'teacher');
      final service = _FakeSyncService([
        _item('t1', backendId: 300, recipientUserId: 20),
      ]);

      await syncAccountNotifications(session: session, syncService: service);
      await Future<void>.delayed(Duration.zero);

      final saved = NotificationLocalStore(
        userKey: 'maestra@ijl.edu.mx',
      ).load();
      expect(saved.map((n) => n.id), ['t1']);
      expect(service.acked, [300]);
    });
  });
}
