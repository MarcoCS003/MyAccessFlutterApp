import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';
import 'package:cliente_flutter_myaccess/features/notifications/background/notification_sync_task.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_local_store.dart';
import 'package:cliente_flutter_myaccess/features/notifications/data/notification_sync_service.dart';
import 'package:cliente_flutter_myaccess/features/notifications/models/notification_item.dart';
import 'package:cliente_flutter_myaccess/features/notifications/providers/notification_provider.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

/// Sync service de prueba: devuelve una lista fija y registra los ACKs.
class _FakeSyncService extends NotificationSyncService {
  _FakeSyncService(this.pending, {this.failAck = false});

  final List<NotificationItem> pending;
  bool failAck;
  final List<int> acked = [];

  @override
  Future<NotificationSyncFetchResult> fetchPending() async {
    return NotificationSyncFetchResult.success(pending);
  }

  @override
  Future<NotificationSyncAckResult> ack(int backendId) async {
    if (failAck) {
      return const NotificationSyncAckResult.failed(
        NotificationSyncFailure(NotificationSyncFailureKind.network),
      );
    }
    acked.add(backendId);
    return const NotificationSyncAckResult.success();
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

        final saved = NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load();
        expect(saved.map((n) => n.id), ['propia']);
        expect(service.acked, [100]);
      },
    );

    test('no escribe nada en el inbox de otra cuenta', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([_item('a', backendId: 100)]);

      await syncAccountNotifications(session: session, syncService: service);

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

      final saved = NotificationLocalStore(
        userKey: 'maestra@ijl.edu.mx',
      ).load();
      expect(saved.map((n) => n.id), ['t1']);
      expect(service.acked, [300]);
    });

    test('deduplica FCM y sync por el mismo backendId', () async {
      final store = NotificationLocalStore(userKey: 'papa@ijl.edu.mx');
      final fcm = NotificationItem.fromFcm({
        'notification_id': '500',
        'user_id': '10',
        'event': 'entry',
        'student_id': '1',
        'person_name': 'Alumno 1',
        'recorded_at': '2026-08-20T07:30:00-06:00',
      });
      final sync = NotificationItem.fromSyncApi({
        'id': 500,
        'user_id': 10,
        'event': 'entry',
        'student_id': 1,
        'person_name': 'Alumno 1',
        'recorded_at': '2026-08-20T07:30:00-06:00',
      });

      final first = await store.upsert(fcm);
      final duplicate = await store.upsert(sync);

      expect(first.inserted, isTrue);
      expect(duplicate.persisted, isTrue);
      expect(duplicate.inserted, isFalse);
      expect(store.load(), hasLength(1));
    });

    test('no hace ACK si Hive no confirma la persistencia', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([
        _item('fallo', backendId: 600, recipientUserId: 10),
      ]);
      await Hive.box('notifications_box').close();

      final result = await syncAccountNotifications(
        session: session,
        syncService: service,
      );

      expect(result.status, NotificationAccountSyncStatus.persistenceError);
      expect(service.acked, isEmpty);
    });

    test('reintenta un ACK fallido sin duplicar la notificación', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([
        _item('reintento', backendId: 700, recipientUserId: 10),
      ], failAck: true);

      final first = await syncAccountNotifications(
        session: session,
        syncService: service,
      );
      expect(first.status, NotificationAccountSyncStatus.ackError);
      expect(
        Hive.box('settings_box').get('pendingNotificationAcks_papa@ijl.edu.mx'),
        [700],
      );

      service.failAck = false;
      final second = await syncAccountNotifications(
        session: session,
        syncService: service,
      );

      expect(second.succeeded, isTrue);
      expect(service.acked, [700]);
      expect(
        Hive.box('settings_box').get('pendingNotificationAcks_papa@ijl.edu.mx'),
        isEmpty,
      );
      expect(
        NotificationLocalStore(userKey: session.userKey).load(),
        hasLength(1),
      );
    });

    test('syncNow usa un JWT por cuenta y aísla un fallo', () async {
      final storage = MockFlutterSecureStorage();
      final memory = <String, String>{};
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((
        invocation,
      ) async {
        return memory[invocation.namedArguments[#key] as String];
      });
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((invocation) async {
        memory[invocation.namedArguments[#key] as String] =
            invocation.namedArguments[#value] as String;
      });

      final sessions = SessionStore(secureStorage: storage);
      await sessions.saveSession(
        user: const User(
          id: 10,
          name: 'Padre',
          email: 'papa@ijl.edu.mx',
          role: 'parent',
        ),
        jwt: 'jwt_a',
      );
      await sessions.saveSession(
        user: const User(
          id: 20,
          name: 'Maestra',
          email: 'maestra@ijl.edu.mx',
          role: 'teacher',
        ),
        jwt: 'jwt_b',
      );

      final services = <String, _FakeSyncService>{
        'papa@ijl.edu.mx': _FakeSyncService([
          _item('padre', backendId: 801, recipientUserId: 10),
        ]),
        'maestra@ijl.edu.mx': _FakeSyncService([
          _item('maestra', backendId: 802, recipientUserId: 20),
        ], failAck: true),
      };
      final parentNotifier = NotificationNotifier(userKey: 'papa@ijl.edu.mx');

      final result = await syncNow(
        sessionStore: sessions,
        serviceFactory: (session, jwt) {
          expect(jwt, session.userKey == 'papa@ijl.edu.mx' ? 'jwt_a' : 'jwt_b');
          return services[session.userKey]!;
        },
      );

      expect(result.accounts['papa@ijl.edu.mx']?.succeeded, isTrue);
      expect(
        result.accounts['maestra@ijl.edu.mx']?.status,
        NotificationAccountSyncStatus.ackError,
      );
      expect(
        NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load(),
        hasLength(1),
      );
      expect(
        NotificationLocalStore(userKey: 'maestra@ijl.edu.mx').load(),
        hasLength(1),
      );
      await parentNotifier.reloadFromLocal();
      expect(parentNotifier.state, hasLength(1));
      expect(
        Hive.box('settings_box').get('lastNotificationSyncAt_papa@ijl.edu.mx'),
        isNotNull,
      );
      expect(
        Hive.box(
          'settings_box',
        ).get('lastNotificationSyncAt_maestra@ijl.edu.mx'),
        isNull,
      );
    });
  });
}
