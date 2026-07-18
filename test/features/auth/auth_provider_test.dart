import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

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

    test('envia role parent y persiste token al registrar', () async {
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
}
