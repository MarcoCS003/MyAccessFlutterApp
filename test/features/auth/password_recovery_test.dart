import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/password_recovery_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

void main() {
  setUp(() async {
    await initializeTestHive();
    registerFallbackValue(FakeRequestOptions());
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('PasswordRecoveryNotifier.sendResetCode', () {
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
    });

    test(
      'emite success con mensaje genérico cuando el backend responde 200',
      () async {
        when(
          () => mockDio.post(
            '/auth/forgot-password',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'message':
                  'Si el correo existe en el sistema, recibirás un código para restablecer tu contraseña.',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
          ),
        );

        final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
        final notifier = PasswordRecoveryNotifier(
          apiService: apiService,
          secureStorage: mockStorage,
        );

        final result = await notifier.sendResetCode('juan@ijl.edu.mx');

        expect(result, isTrue);
        expect(notifier.state.status, RecoveryStatus.success);
        expect(notifier.state.successMessage, contains('código'));
      },
    );

    test('emite error cuando el backend responde 422', () async {
      when(
        () => mockDio.post(
          '/auth/forgot-password',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          response: Response(
            data: {
              'message': 'The email field must be a valid email address.',
              'errors': {
                'email': ['The email field must be a valid email address.'],
              },
            },
            statusCode: 422,
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = PasswordRecoveryNotifier(
        apiService: apiService,
        secureStorage: mockStorage,
      );

      final result = await notifier.sendResetCode('correo-malo');

      expect(result, isFalse);
      expect(notifier.state.status, RecoveryStatus.error);
      expect(notifier.state.fieldErrors['email'], isNotNull);
    });

    test('muestra mensaje amigable cuando el backend responde 429', () async {
      when(
        () => mockDio.post(
          '/auth/forgot-password',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/forgot-password'),
          response: Response(
            data: {'message': 'Too Many Attempts.'},
            statusCode: 429,
            requestOptions: RequestOptions(path: '/auth/forgot-password'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = PasswordRecoveryNotifier(
        apiService: apiService,
        secureStorage: mockStorage,
      );

      final result = await notifier.sendResetCode('juan@ijl.edu.mx');

      expect(result, isFalse);
      expect(notifier.state.status, RecoveryStatus.error);
      expect(notifier.state.errorMessage, contains('Demasiados intentos'));
    });
  });

  group('PasswordRecoveryNotifier.resetPassword', () {
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();
      when(
        () => mockStorage.delete(key: any(named: 'key')),
      ).thenAnswer((_) async {});
    });

    test('descarta el token local y emite success al restablecer', () async {
      when(
        () => mockDio.post(
          '/auth/reset-password',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'message':
                'Contraseña restablecida exitosamente. Inicia sesión con tu nueva contraseña.',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/auth/reset-password'),
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = PasswordRecoveryNotifier(
        apiService: apiService,
        secureStorage: mockStorage,
      );

      final result = await notifier.resetPassword(
        email: 'juan@ijl.edu.mx',
        token: 'codigo-del-correo',
        password: 'NuevaPassword123!',
        passwordConfirmation: 'NuevaPassword123!',
      );

      expect(result, isTrue);
      expect(notifier.state.status, RecoveryStatus.success);
      expect(notifier.state.successMessage, contains('restablecida'));
      verify(() => mockStorage.delete(key: 'jwt_token')).called(1);
    });

    test(
      'expone fieldErrors cuando el código es inválido (422 en campo email)',
      () async {
        when(
          () => mockDio.post(
            '/auth/reset-password',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/reset-password'),
            response: Response(
              data: {
                'message': 'El código es inválido o ha expirado.',
                'errors': {
                  'email': ['El código es inválido o ha expirado.'],
                },
              },
              statusCode: 422,
              requestOptions: RequestOptions(path: '/auth/reset-password'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
        final notifier = PasswordRecoveryNotifier(
          apiService: apiService,
          secureStorage: mockStorage,
        );

        final result = await notifier.resetPassword(
          email: 'juan@ijl.edu.mx',
          token: 'codigo-incorrecto',
          password: 'NuevaPassword123!',
          passwordConfirmation: 'NuevaPassword123!',
        );

        expect(result, isFalse);
        expect(notifier.state.status, RecoveryStatus.error);
        expect(notifier.state.fieldErrors['email'], isNotNull);
        verifyNever(() => mockStorage.delete(key: 'jwt_token'));
      },
    );

    test('muestra mensaje amigable cuando el backend responde 429', () async {
      when(
        () => mockDio.post(
          '/auth/reset-password',
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/reset-password'),
          response: Response(
            data: {'message': 'Too Many Attempts.'},
            statusCode: 429,
            requestOptions: RequestOptions(path: '/auth/reset-password'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
      final notifier = PasswordRecoveryNotifier(
        apiService: apiService,
        secureStorage: mockStorage,
      );

      final result = await notifier.resetPassword(
        email: 'juan@ijl.edu.mx',
        token: 'codigo',
        password: 'NuevaPassword123!',
        passwordConfirmation: 'NuevaPassword123!',
      );

      expect(result, isFalse);
      expect(notifier.state.errorMessage, contains('Demasiados intentos'));
    });
  });
}
