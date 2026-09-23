import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cliente_flutter_myaccess/core/constants/app_constants.dart';
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

  group('AuthNotifier.refreshUser', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();

      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer(
        (_) async {},
      );
    });

    AuthNotifier buildNotifier() {
      final apiService = ApiService(
        dio: mockDio,
        secureStorage: mockStorage,
      );
      return AuthNotifier(
        skipInitialCheck: true,
        firebaseMessaging: mockFirebaseMessaging,
        secureStorage: mockStorage,
        apiService: apiService,
      );
    }

    test(
      '200 con teacher poblado actualiza state.user.teacher',
      () async {
        when(
          () => mockDio.get(
            '/user',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'id': 42,
              'name': 'Maestra',
              'email': 'm@ijl.mx',
              'role': 'teacher',
              'teacher': {'id': 109, 'qr_code': 'DEMO-TEACHER-001'},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/user'),
          ),
        );

        final notifier = buildNotifier();
        notifier.state = AuthState(
          status: AuthStatus.authenticated,
          user: notifier.state.user,
        );

        await notifier.refreshUser();

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, isNotNull);
        expect(notifier.state.user!.teacher, isNotNull);
        expect(notifier.state.user!.teacher!.id, 109);
        expect(notifier.state.user!.teacher!.qrCode, 'DEMO-TEACHER-001');
      },
    );

    test(
      '200 con teacher null carga el user pero deja teacher en null',
      () async {
        when(
          () => mockDio.get(
            '/user',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'id': 42,
              'name': 'Maestra',
              'email': 'm@ijl.mx',
              'role': 'teacher',
              'teacher': null,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/user'),
          ),
        );

        final notifier = buildNotifier();

        await notifier.refreshUser();

        expect(notifier.state.status, AuthStatus.authenticated);
        expect(notifier.state.user, isNotNull);
        expect(notifier.state.user!.teacher, isNull);
      },
    );

    test(
      'error de red no cambia state y no rompe la sesión',
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
              data: {'message': 'server exploded'},
              statusCode: 500,
              requestOptions: RequestOptions(path: '/user'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final notifier = buildNotifier();

        await notifier.refreshUser();

        // El estado sigue siendo el inicial (initial); refreshUser es
        // best-effort y no debe tumbar la sesión.
        expect(notifier.state.status, AuthStatus.initial);
        expect(notifier.state.user, isNull);
      },
    );

    test(
      '200 persiste el usuario actualizado en auth_box',
      () async {
        when(
          () => mockDio.get(
            '/user',
            queryParameters: any(named: 'queryParameters'),
            options: any(named: 'options'),
          ),
        ).thenAnswer(
          (_) async => Response(
            data: {
              'id': 42,
              'name': 'Maestra',
              'email': 'm@ijl.mx',
              'role': 'teacher',
              'teacher': {'id': 109, 'qr_code': 'NEW-QR-42'},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/user'),
          ),
        );

        final notifier = buildNotifier();
        await notifier.refreshUser();

        final box = Hive.box(AppConstants.authBox);
        final cached = box.get('user') as Map<dynamic, dynamic>?;
        expect(cached, isNotNull);
        final teacher = cached!['teacher'] as Map<dynamic, dynamic>?;
        expect(teacher, isNotNull);
        expect(teacher!['qr_code'], 'NEW-QR-42');
      },
    );
  });
}