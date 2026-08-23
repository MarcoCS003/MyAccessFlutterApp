import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/user.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

void main() {
  late MockFlutterSecureStorage storage;
  late Map<String, String> memory;
  late SessionStore store;

  const userA = User(
    id: 1,
    name: 'Papá Uno',
    email: 'papa@ijl.edu.mx',
    role: 'parent',
  );
  const userB = User(
    id: 2,
    name: 'Maestra Dos',
    email: 'maestra@ijl.edu.mx',
    role: 'teacher',
  );

  setUp(() async {
    await initializeTestHive();
    memory = {};
    storage = MockFlutterSecureStorage();
    when(
      () => storage.read(key: any(named: 'key')),
    ).thenAnswer((i) async => memory[i.namedArguments[#key] as String]);
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((i) async {
      memory[i.namedArguments[#key] as String] =
          i.namedArguments[#value] as String;
    });
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((i) async {
      memory.remove(i.namedArguments[#key]);
    });
    store = SessionStore(secureStorage: storage);
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  test('saveSession + listSessions devuelve las cuentas guardadas', () async {
    await store.saveSession(user: userA, jwt: 'jwt_a');
    await store.saveSession(user: userB, jwt: 'jwt_b');

    final sessions = store.listSessions();
    expect(sessions.length, 2);
    expect(sessions.map((s) => s.user.email), contains(userA.email));
    expect(sessions.map((s) => s.user.email), contains(userB.email));
    expect(await store.getJwt('papa@ijl.edu.mx'), 'jwt_a');
    expect(await store.getJwt('maestra@ijl.edu.mx'), 'jwt_b');
  });

  test('saveSession actualiza una cuenta existente sin duplicarla', () async {
    await store.saveSession(user: userA, jwt: 'jwt_a');
    await store.saveSession(user: userA, jwt: 'jwt_a2');

    expect(store.listSessions().length, 1);
    expect(await store.getJwt('papa@ijl.edu.mx'), 'jwt_a2');
  });

  test('removeSession elimina cuenta y JWT sin tocar las demás', () async {
    await store.saveSession(user: userA, jwt: 'jwt_a');
    await store.saveSession(user: userB, jwt: 'jwt_b');

    await store.removeSession('papa@ijl.edu.mx');

    expect(store.listSessions().length, 1);
    expect(await store.getJwt('papa@ijl.edu.mx'), isNull);
    expect(await store.getJwt('maestra@ijl.edu.mx'), 'jwt_b');
  });

  test(
    'setActive copia JWT y usuario de la cuenta a la sesión activa',
    () async {
      await store.saveSession(user: userA, jwt: 'jwt_a');
      await store.saveSession(user: userB, jwt: 'jwt_b');

      final ok = await store.setActive('maestra@ijl.edu.mx');

      expect(ok, isTrue);
      expect(memory['jwt_token'], 'jwt_b');
      expect(await store.getJwt('maestra@ijl.edu.mx'), 'jwt_b');
    },
  );

  test('setActive falla si la cuenta no existe o no tiene JWT', () async {
    expect(await store.setActive('nadie@ijl.edu.mx'), isFalse);

    await store.saveSession(user: userA, jwt: 'jwt_a');
    memory.remove('jwt_token_papa@ijl.edu.mx');
    expect(await store.setActive('papa@ijl.edu.mx'), isFalse);
  });

  test(
    'clearActive borra la sesión activa pero conserva las cuentas',
    () async {
      await store.saveSession(user: userA, jwt: 'jwt_a');
      await store.setActive('papa@ijl.edu.mx');

      await store.clearActive();

      expect(memory['jwt_token'], isNull);
      expect(store.listSessions().length, 1);
      expect(await store.getJwt('papa@ijl.edu.mx'), 'jwt_a');
    },
  );
}
