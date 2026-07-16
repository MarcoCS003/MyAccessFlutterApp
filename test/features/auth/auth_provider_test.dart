import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cliente_flutter_myaccess/features/auth/models/auth_state.dart';
import 'package:cliente_flutter_myaccess/features/auth/providers/auth_provider.dart';
import 'package:cliente_flutter_myaccess/services/api_service.dart';

import '../../mocks/api_mocks.dart';
import '../../test_helpers.dart';

class FakeAuthCredential extends Fake implements firebase_auth.AuthCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  setUp(() async {
    await initializeTestHive();
    registerFallbackValue(FakeRequestOptions());
    registerFallbackValue(FakeAuthCredential());
  });

  tearDown(() async {
    await cleanUpTestHive();
  });

  group('AuthNotifier.signInWithGoogle', () {
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAccount mockGoogleUser;
    late MockGoogleSignInAuthentication mockGoogleAuth;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockUserCredential mockUserCredential;
    late MockFirebaseUser mockFirebaseUser;
    late MockDio mockDio;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockGoogleSignIn = MockGoogleSignIn();
      mockGoogleUser = MockGoogleSignInAccount();
      mockGoogleAuth = MockGoogleSignInAuthentication();
      mockFirebaseAuth = MockFirebaseAuth();
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockUserCredential = MockUserCredential();
      mockFirebaseUser = MockFirebaseUser();
      mockDio = MockDio();
      configureMockDioOptions(mockDio);
      mockStorage = MockFlutterSecureStorage();

      when(
        () => mockGoogleSignIn.signIn(),
      ).thenAnswer((_) async => mockGoogleUser);
      when(
        () => mockGoogleUser.authentication,
      ).thenAnswer((_) async => mockGoogleAuth);
      when(() => mockGoogleAuth.accessToken).thenReturn('google_access_token');
      when(() => mockGoogleAuth.idToken).thenReturn('google_id_token');
      when(() => mockGoogleUser.displayName).thenReturn('Marco Test');
      when(() => mockGoogleUser.email).thenReturn('marco@test.com');
      when(() => mockGoogleUser.photoUrl).thenReturn('https://photo.url');

      when(
        () => mockFirebaseAuth.signInWithCredential(any()),
      ).thenAnswer((_) async => mockUserCredential);
      when(() => mockUserCredential.user).thenReturn(mockFirebaseUser);
      when(
        () => mockFirebaseUser.getIdToken(),
      ).thenAnswer((_) async => 'firebase_id_token');

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

    test(
      'emite error y no persiste token simulado cuando el backend falla',
      () async {
        when(
          () => mockDio.post(
            '/auth/google-login',
            data: any(named: 'data'),
            options: any(named: 'options'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/google-login'),
            response: Response(
              data: {'message': 'Token de Google inválido'},
              statusCode: 401,
              requestOptions: RequestOptions(path: '/auth/google-login'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        final apiService = ApiService(dio: mockDio, secureStorage: mockStorage);
        final notifier = AuthNotifier(
          skipInitialCheck: true,
          googleSignIn: mockGoogleSignIn,
          firebaseAuth: mockFirebaseAuth,
          firebaseMessaging: mockFirebaseMessaging,
          secureStorage: mockStorage,
          apiService: apiService,
        );

        await notifier.signInWithGoogle();

        expect(notifier.state.status, AuthStatus.error);
        expect(notifier.state.errorMessage, isNotNull);
        verifyNever(
          () => mockStorage.write(
            key: any(named: 'key', that: equals('jwt_token')),
            value: any(named: 'value', that: contains('simulated')),
          ),
        );
      },
    );

    test(
      'persiste token real y emite autenticado cuando el backend responde',
      () async {
        when(
          () => mockDio.post(
            '/auth/google-login',
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
                'avatar': 'https://photo.url',
                'role': 'parent',
              },
              'token': 'real_backend_token',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/auth/google-login'),
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
          googleSignIn: mockGoogleSignIn,
          firebaseAuth: mockFirebaseAuth,
          firebaseMessaging: mockFirebaseMessaging,
          secureStorage: mockStorage,
          apiService: apiService,
        );

        await notifier.signInWithGoogle();

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
}
