import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/data/session_store.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../mocks/auth_mocks.dart' show MockFirebaseMessaging;
import '../../test_helpers.dart';
import 'auth_provider_test.dart' show useInMemoryStorage;

void main() {
  setUp(() async {
    await initializeTestHive();
    registerFallbackValue(FakeRequestOptions());
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('AuthNotifier.changePassword', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;
    late Map<String, String> memory;

    const teacherWithFlag = {
      'id': 2,
      'name': 'Maestra Dos',
      'email': 'maestra@ijl.edu.mx',
      'role': 'teacher',
      'must_change_password': true,
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

    Future<AuthNotifier> loggedInNotifier() async {
      final notifier = buildNotifier();
      await notifier.signInWithEmailPassword('maestra@ijl.edu.mx', 'x');
      expect(notifier.state.user!.mustChangePassword, isTrue);
      return notifier;
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
      ).thenAnswer(
        (_) async => Response(
          data: {'user': teacherWithFlag, 'access_token': 'jwt_maestra'},
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
    });

    test(
      'éxito: apaga el flag, conserva el JWT y actualiza la sesión',
      () async {
        when(
          () => mockDio.post(
            '/auth/change-password',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'message': 'Contraseña actualizada',
              'user': {...teacherWithFlag, 'must_change_password': false},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/change-password'),
          ),
        );

        final notifier = await loggedInNotifier();
        await notifier.changePassword(
          currentPassword: '@qwerty1234',
          newPassword: 'NuevaSegura123!',
          confirmation: 'NuevaSegura123!',
        );

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user!.mustChangePassword, isFalse);
        // El JWT no cambia.
        expect(memory['jwt_token'], 'jwt_maestra');
        // La sesión guardada queda con el flag apagado.
        final sessions = SessionStore(
          secureStorage: mockStorage,
        ).listSessions();
        expect(sessions.single.user.mustChangePassword, isFalse);
      },
    );

    test(
      '422: conserva la sesión activa y expone fieldErrors (no es logout)',
      () async {
        when(
          () => mockDio.post(
            '/auth/change-password',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/change-password'),
            response: Response(
              data: {
                'message': 'La contraseña actual es incorrecta',
                'errors': {
                  'current_password': ['La contraseña actual es incorrecta'],
                },
              },
              statusCode: 422,
              requestOptions: RequestOptions(path: '/auth/change-password'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final notifier = await loggedInNotifier();
        await notifier.changePassword(
          currentPassword: 'incorrecta',
          newPassword: 'NuevaSegura123!',
          confirmation: 'NuevaSegura123!',
        );

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, isNotNull);
        expect(notifier.state.user!.mustChangePassword, isTrue);
        expect(notifier.state.fieldErrors['current_password'], isNotNull);
      },
    );
  });
}
