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

/// Sync service de prueba: devuelve una lista fija de faltantes y registra
/// los `local_ids` recibidos en cada llamada al diff.
class _FakeSyncService extends NotificationSyncService {
  _FakeSyncService(this.missing, {this.failure});

  final List<NotificationItem> missing;
  NotificationSyncFailure? failure;
  final List<List<int>> requests = [];

  int get calls => requests.length;

  @override
  Future<NotificationSyncFetchResult> fetchDiff(List<int> localIds) async {
    requests.add(localIds);
    final currentFailure = failure;
    if (currentFailure != null) {
      return NotificationSyncFetchResult.failed(currentFailure);
    }
    return NotificationSyncFetchResult.success(missing);
  }
}

NotificationItem _item(
  String id, {
  int? backendId,
  int? recipientUserId,
  DateTime? timestamp,
}) {
  return NotificationItem(
    id: id,
    backendId: backendId,
    recipientUserId: recipientUserId,
    type: 'student_attendance',
    event: 'check_in',
    studentName: 'Alumno $id',
    studentId: 1,
    timestamp: timestamp ?? DateTime(2026, 8, 20, 7, 30),
  );
}

SavedSession _session(String email, int id, String role) => SavedSession(
  userKey: email,
  user: User(id: id, name: email, email: email, role: role),
);

/// SessionStore con SecureStorage en memoria y dos cuentas guardadas.
Future<SessionStore> _seedSessions() async {
  final storage = MockFlutterSecureStorage();
  final memory = <String, String>{};
  when(() => storage.read(key: any(named: 'key'))).thenAnswer(
    (invocation) async => memory[invocation.namedArguments[#key] as String],
  );
  when(
    () => storage.write(key: any(named: 'key'), value: any(named: 'value')),
  ).thenAnswer((invocation) async {
    memory[invocation.namedArguments[#key] as String] =
        invocation.namedArguments[#value] as String;
  });

  final store = SessionStore(secureStorage: storage);
  await store.saveSession(
    user: const User(
      id: 10,
      name: 'Padre',
      email: 'papa@ijl.edu.mx',
      role: 'parent',
    ),
    jwt: 'jwt_a',
  );
  await store.saveSession(
    user: const User(
      id: 20,
      name: 'Maestra',
      email: 'maestra@ijl.edu.mx',
      role: 'teacher',
    ),
    jwt: 'jwt_b',
  );
  return store;
}

void main() {
  setUp(() async {
    await initializeTestHive();
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('syncAccountNotifications', () {
    test('envía los últimos 10 backendIds locales y guarda faltantes', () async {
      final store = NotificationLocalStore(userKey: 'papa@ijl.edu.mx');
      final locals = [
        for (var i = 1; i <= 12; i++)
          _item(
            'local_$i',
            backendId: i,
            timestamp: DateTime(2026, 8, 20, 7, i),
          ),
      ];
      await store.saveAll(locals);

      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([
        _item('nueva', backendId: 200, recipientUserId: 10),
      ]);

      final result = await syncAccountNotifications(
        session: session,
        syncService: service,
      );

      expect(result.succeeded, isTrue);
      expect(result.insertedCount, 1);
      expect(service.requests.single, [12, 11, 10, 9, 8, 7, 6, 5, 4, 3]);
      final saved = store.load();
      expect(saved.map((n) => n.id), contains('nueva'));
    });

    test('descarta items con user_id de otra cuenta', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([
        _item('propia', backendId: 100, recipientUserId: 10),
        _item('ajena', backendId: 200, recipientUserId: 20),
      ]);

      await syncAccountNotifications(session: session, syncService: service);

      final saved = NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load();
      expect(saved.map((n) => n.id), ['propia']);
    });

    test('no escribe nada en el inbox de otra cuenta', () async {
      final session = _session('papa@ijl.edu.mx', 10, 'parent');
      final service = _FakeSyncService([_item('a', backendId: 100)]);

      await syncAccountNotifications(session: session, syncService: service);

      final otherInbox = NotificationLocalStore(
        userKey: 'maestra@ijl.edu.mx',
      ).load();
      expect(otherInbox, isEmpty);
    });

    test('deduplica FCM y diff por el mismo backendId', () async {
      final store = NotificationLocalStore(userKey: 'papa@ijl.edu.mx');
      final fcm = NotificationItem.fromFcm({
        'notification_id': '500',
        'user_id': '10',
        'event': 'entry',
        'student_id': '1',
        'person_name': 'Alumno 1',
        'recorded_at': '2026-08-20T07:30:00-06:00',
      });
      final diff = NotificationItem.fromSyncApi({
        'id': 500,
        'user_id': 10,
        'event': 'entry',
        'student_id': 1,
        'person_name': 'Alumno 1',
        'recorded_at': '2026-08-20T07:30:00-06:00',
      });

      final first = await store.upsert(fcm);
      final duplicate = await store.upsert(diff);

      expect(first.inserted, isTrue);
      expect(duplicate.persisted, isTrue);
      expect(duplicate.inserted, isFalse);
      expect(store.load(), hasLength(1));
    });

    test('informa persistenceError si Hive no confirma la escritura', () async {
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
      await Hive.openBox('notifications_box');
    });
  });

  group('executeWindowSync', () {
    final windowStart = DateTime(2026, 8, 29, 9);

    test('marca la ventana por cuenta y no repite en la misma ventana', () async {
      final sessions = await _seedSessions();
      final service = _FakeSyncService([
        _item('padre', backendId: 801, recipientUserId: 10),
      ]);

      final first = await executeWindowSync(
        windowStart: windowStart,
        sessionStore: sessions,
        serviceFactory: (session, jwt) => service,
      );

      expect(first.accounts['papa@ijl.edu.mx']?.succeeded, isTrue);
      expect(
        Hive.box('settings_box').get('lastDiffSync_papa@ijl.edu.mx'),
        '2026-08-29:09',
      );
      final callsAfterFirst = service.calls;

      final second = await executeWindowSync(
        windowStart: windowStart,
        sessionStore: sessions,
        serviceFactory: (session, jwt) => service,
      );

      expect(
        second.accounts['papa@ijl.edu.mx']?.status,
        NotificationAccountSyncStatus.alreadySynced,
      );
      expect(service.calls, callsAfterFirst);

      // Otra ventana (15:00) sí vuelve a sincronizar.
      await executeWindowSync(
        windowStart: DateTime(2026, 8, 29, 15),
        sessionStore: sessions,
        serviceFactory: (session, jwt) => service,
      );
      expect(service.calls, greaterThan(callsAfterFirst));
      expect(
        Hive.box('settings_box').get('lastDiffSync_papa@ijl.edu.mx'),
        '2026-08-29:15',
      );
    });

    test(
      'usa un JWT por cuenta, aísla un fallo y no marca la cuenta fallida',
      () async {
        final sessions = await _seedSessions();
        final services = <String, _FakeSyncService>{
          'papa@ijl.edu.mx': _FakeSyncService([
            _item('padre', backendId: 801, recipientUserId: 10),
          ]),
          'maestra@ijl.edu.mx': _FakeSyncService(
            [],
            failure: const NotificationSyncFailure(
              NotificationSyncFailureKind.network,
            ),
          ),
        };
        final parentNotifier = NotificationNotifier(userKey: 'papa@ijl.edu.mx');

        final result = await executeWindowSync(
          windowStart: windowStart,
          sessionStore: sessions,
          serviceFactory: (session, jwt) {
            expect(
              jwt,
              session.userKey == 'papa@ijl.edu.mx' ? 'jwt_a' : 'jwt_b',
            );
            return services[session.userKey]!;
          },
        );

        expect(result.accounts['papa@ijl.edu.mx']?.succeeded, isTrue);
        expect(
          result.accounts['maestra@ijl.edu.mx']?.status,
          NotificationAccountSyncStatus.networkError,
        );
        expect(
          NotificationLocalStore(userKey: 'papa@ijl.edu.mx').load(),
          hasLength(1),
        );
        await parentNotifier.reloadFromLocal();
        expect(parentNotifier.state, hasLength(1));
        expect(
          Hive.box('settings_box').get('lastDiffSync_papa@ijl.edu.mx'),
          '2026-08-29:09',
        );
        expect(
          Hive.box('settings_box').get('lastDiffSync_maestra@ijl.edu.mx'),
          isNull,
        );
      },
    );

    test('syncNow no exige ventana activa', () async {
      final sessions = await _seedSessions();
      final service = _FakeSyncService([
        _item('padre', backendId: 900, recipientUserId: 10),
      ]);

      final result = await syncNow(
        sessionStore: sessions,
        serviceFactory: (session, jwt) => service,
      );

      expect(result.accounts['papa@ijl.edu.mx']?.succeeded, isTrue);
      expect(service.calls, greaterThan(0));
    });
  });
}
