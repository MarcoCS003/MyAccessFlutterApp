import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

/// Configura un MockFlutterSecureStorage con un mapa en memoria real,
/// necesario para probar multi-sesión (setActive lee JWTs guardados).
void useInMemoryStorage(
  MockFlutterSecureStorage storage,
  Map<String, String> memory,
) {
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
}

void main() {
  setUp(() async {
    await initializeTestHive();
    registerFallbackValue(FakeRequestOptions());
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('AuthNotifier.signInWithEmailPassword', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();

      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'fcm_token');
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => const Stream<String>.empty());

      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
    });

    test('emite error cuando el backend responde 401', () async {
      when(
        () => mockDio.post(
          '/auth/login',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
            data: {'message': 'Credenciales incorrectas'},
            statusCode: 401,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = AuthNotifier(
        skipInitialCheck: true,
        firebaseMessaging: mockFirebaseMessaging,
        secureStorage: mockStorage,
        apiService: apiService,
      );

      await notifier.signInWithEmailPassword('test@ijl.edu.mx', 'wrong');

      expect(notifier.state.status, AuthStatus.error);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test(
      'persiste token y emite autenticado cuando el backend responde',
      () async {
        when(
          () => mockDio.post(
            '/auth/login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'user': {
                'id': 42,
                'name': 'Marco Test',
                'email': 'marco@test.com',
                'role': 'parent',
              },
              'access_token': 'real_backend_token',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/login'),
          ),
        );

        when(
          () => mockDio.post(
            '/update-fcm-token',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {'message': 'OK'},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/update-fcm-token'),
          ),
        );

        final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
        final notifier = AuthNotifier(
          skipInitialCheck: true,
          firebaseMessaging: mockFirebaseMessaging,
          secureStorage: mockStorage,
          apiService: apiService,
        );

        await notifier.signInWithEmailPassword('marco@test.com', 'password');

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, isNotNull);
        expect(notifier.state.user!.id, 42);
        verify(
          () =>
              mockStorage.write(key: 'jwt_token', value: 'real_backend_token'),
        ).called(1);
      },
    );
  });

  group('AuthNotifier.signUp', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();

      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'fcm_token');
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => const Stream<String>.empty());

      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
    });

    test('registra sin role y persiste token al registrar', () async {
      when(
        () => mockDio.post(
          '/auth/register',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'user': {
              'id': 7,
              'name': 'Juan Pérez',
              'email': 'juan@ijl.edu.mx',
              'role': 'parent',
            },
            'access_token': 'register_token',
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/auth/register'),
        ),
      );

      when(
        () => mockDio.post(
          '/update-fcm-token',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'message': 'OK'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/update-fcm-token'),
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = AuthNotifier(
        skipInitialCheck: true,
        firebaseMessaging: mockFirebaseMessaging,
        secureStorage: mockStorage,
        apiService: apiService,
      );

      await notifier.signUp(
        name: 'Juan Pérez',
        email: 'juan@ijl.edu.mx',
        password: 'ContraseñaSegura123!',
        passwordConfirmation: 'ContraseñaSegura123!',
      );

      expect(notifier.state.status, AuthStatus.authenticated);
      expect(notifier.state.user, isNotNull);
      expect(notifier.state.user!.role, 'parent');
      verify(
        () => mockStorage.write(key: 'jwt_token', value: 'register_token'),
      ).called(1);
    });
  });

  group('AuthNotifier multi-sesión', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;
    late Map<String, String> memory;

    const users = {
      'papa@ijl.edu.mx': {
        'id': 1,
        'name': 'Papá Uno',
        'email': 'papa@ijl.edu.mx',
        'role': 'parent',
      },
      'maestra@ijl.edu.mx': {
        'id': 2,
        'name': 'Maestra Dos',
        'email': 'maestra@ijl.edu.mx',
        'role': 'teacher',
      },
    };

    AuthNotifier buildNotifier() {
      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      return AuthNotifier(
        skipInitialCheck: true,
        firebaseMessaging: mockFirebaseMessaging,
        secureStorage: mockStorage,
        apiService: apiService,
      );
    }

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();
      memory = {};
      useInMemoryStorage(mockStorage, memory);

      when(
        () => mockFirebaseMessaging.getToken(),
      ).thenAnswer((_) async => 'fcm_token');
      when(() => mockFirebaseMessaging.deleteToken()).thenAnswer((_) async {});
      when(
        () => mockFirebaseMessaging.onTokenRefresh,
      ).thenAnswer((_) => const Stream<String>.empty());

      when(
        () => mockDio.post(
          '/auth/login',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((inv) async {
        final data = inv.namedArguments[#data] as Map;
        final email = data['email'] as String;
        return Response(
          data: {'user': users[email], 'access_token': 'jwt_$email'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/login'),
        );
      });

      when(
        () => mockDio.post(
          '/update-fcm-token',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'message': 'OK'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/update-fcm-token'),
        ),
      );

      when(
        () => mockDio.get(
          '/user',
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {'id': 1},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/user'),
        ),
      );
    });

    test('login de 2 cuentas guarda ambas sesiones', () async {
      final notifier = buildNotifier();

      await notifier.signInWithEmailPassword('papa@ijl.edu.mx', 'x');
      await notifier.signInWithEmailPassword('maestra@ijl.edu.mx', 'x');

      final sessions = SessionStore(secureStorage: mockStorage).listSessions();
      expect(sessions.length, 2);
      expect(notifier.state.user!.email, 'maestra@ijl.edu.mx');
      expect(memory['jwt_token'], 'jwt_maestra@ijl.edu.mx');
      expect(memory['jwt_token_papa@ijl.edu.mx'], 'jwt_papa@ijl.edu.mx');
    });

    test(
      'signOut con otra cuenta guardada hace auto-switch y rota token',
      () async {
        final notifier = buildNotifier();
        await notifier.signInWithEmailPassword('papa@ijl.edu.mx', 'x');
        await notifier.signInWithEmailPassword('maestra@ijl.edu.mx', 'x');

        await notifier.signOut();

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user!.email, 'papa@ijl.edu.mx');
        expect(memory['jwt_token'], 'jwt_papa@ijl.edu.mx');
        verify(() => mockFirebaseMessaging.deleteToken()).called(1);
        final sessions = SessionStore(
          secureStorage: mockStorage,
        ).listSessions();
        expect(sessions.length, 1);
        expect(sessions.single.user.email, 'papa@ijl.edu.mx');
      },
    );

    test(
      'signOut con la última cuenta queda no autenticado y borra token',
      () async {
        final notifier = buildNotifier();
        await notifier.signInWithEmailPassword('papa@ijl.edu.mx', 'x');

        await notifier.signOut();

        expect(notifier.state.status, AuthStatus.unauthenticated);
        expect(memory['jwt_token'], isNull);
        verify(() => mockFirebaseMessaging.deleteToken()).called(1);
      },
    );

    test(
      'switchAccount cambia la sesión activa tras validar con /user',
      () async {
        final notifier = buildNotifier();
        await notifier.signInWithEmailPassword('papa@ijl.edu.mx', 'x');
        await notifier.signInWithEmailPassword('maestra@ijl.edu.mx', 'x');

        final ok = await notifier.switchAccount('papa@ijl.edu.mx');

        expect(ok, isTrue);
        expect(notifier.state.user!.email, 'papa@ijl.edu.mx');
        expect(memory['jwt_token'], 'jwt_papa@ijl.edu.mx');
        // Ambas sesiones siguen guardadas.
        expect(
          SessionStore(secureStorage: mockStorage).listSessions().length,
          2,
        );
      },
    );

    test(
      'switchAccount con 401 elimina la sesión expirada y restaura la anterior',
      () async {
        when(
          () => mockDio.get(
            '/user',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/user'),
            response: Response(
              data: {'message': 'Unauthenticated'},
              statusCode: 401,
              requestOptions: RequestOptions(path: '/user'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final notifier = buildNotifier();
        await notifier.signInWithEmailPassword('papa@ijl.edu.mx', 'x');
        await notifier.signInWithEmailPassword('maestra@ijl.edu.mx', 'x');

        final ok = await notifier.switchAccount('papa@ijl.edu.mx');

        expect(ok, isFalse);
        // Sigue activa la cuenta anterior.
        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user!.email, 'maestra@ijl.edu.mx');
        expect(memory['jwt_token'], 'jwt_maestra@ijl.edu.mx');
        expect(notifier.state.errorMessage, isNotNull);
        // La sesión expirada se eliminó del dispositivo.
        final sessions = SessionStore(
          secureStorage: mockStorage,
        ).listSessions();
        expect(sessions.length, 1);
        expect(sessions.single.user.email, 'maestra@ijl.edu.mx');
      },
    );
  });
}
