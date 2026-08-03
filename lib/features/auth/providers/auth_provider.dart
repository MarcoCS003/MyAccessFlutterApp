import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../services/api_service.dart';
import '../models/auth_state.dart';
import '../models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    FirebaseMessaging? firebaseMessaging,
    FlutterSecureStorage? secureStorage,
    ApiService? apiService,
    bool skipInitialCheck = false,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _apiService = apiService ?? ApiService(),
       super(const AuthState()) {
    if (!skipInitialCheck) {
      checkAuthStatus();
    }
  }

  final FirebaseMessaging _firebaseMessaging;
  final FlutterSecureStorage _secureStorage;
  final ApiService _apiService;

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final fcmToken = await _firebaseMessaging.getToken();

      final response =
          await _apiService.post(
                '/auth/login',
                data: {
                  'email': email,
                  'password': password,
                  'fcm_token': fcmToken,
                },
                requiresAuth: false,
              )
              as Map<String, dynamic>;

      final accessToken = response['access_token'] as String? ?? '';
      if (accessToken.isEmpty) {
        throw Exception('El backend no devolvió token de acceso');
      }

      final user = User.fromJson(response['user'] as Map<String, dynamic>);

      await _persistSession(jwtToken: accessToken, user: user);
      await _registerFcmToken();
      _listenToTokenRefresh();

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
    } catch (e, st) {
      debugPrint('signInWithEmailPassword falló: $e\n$st');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Credenciales incorrectas o error del servidor',
      );
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final fcmToken = await _firebaseMessaging.getToken();

      final response =
          await _apiService.post(
                '/auth/register',
                data: {
                  'name': name,
                  'email': email,
                  'password': password,
                  'password_confirmation': passwordConfirmation,
                  'fcm_token': fcmToken,
                },
                requiresAuth: false,
              )
              as Map<String, dynamic>;

      final accessToken = response['access_token'] as String? ?? '';
      if (accessToken.isEmpty) {
        throw Exception('El backend no devolvió token de acceso');
      }

      final user = User.fromJson(response['user'] as Map<String, dynamic>);

      await _persistSession(jwtToken: accessToken, user: user);
      await _registerFcmToken();
      _listenToTokenRefresh();

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (e) {
      state = AuthState(status: AuthStatus.error, errorMessage: e.message);
    } catch (e, st) {
      debugPrint('signUp falló: $e\n$st');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Error al registrar. Verifica tus datos.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: AppConstants.jwtTokenKey);
      // La BD local (hijos, notificaciones, settings) se conserva al cerrar
      // sesión: los datos de cada cuenta están namespacedos por userKey
      // (email) en Hive, así que nada se mezcla al alternar cuentas en el
      // mismo dispositivo. La sesión termina al borrar el JWT;
      // checkAuthStatus exige token + usuario, así que sin token queda no
      // autenticado. auth_box['user'] se conserva como última cuenta
      // conocida (la usan los handlers FCM para namespacer escrituras).
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Error al cerrar sesión: ${e.toString()}',
      );
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
      final box = Hive.box(AppConstants.authBox);
      final userData = box.get('user') as Map<dynamic, dynamic>?;

      if (token != null && token.isNotEmpty && userData != null) {
        final user = User.fromJson(
          userData.map((key, value) => MapEntry(key.toString(), value)),
        );
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _persistSession({
    required String jwtToken,
    required User user,
  }) async {
    await _secureStorage.write(key: AppConstants.jwtTokenKey, value: jwtToken);
    final box = Hive.box(AppConstants.authBox);
    await box.put('user', user.toJson());
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _apiService.post(
        '/update-fcm-token',
        data: {'fcm_token': fcmToken},
      );
      debugPrint('FCM token registered successfully');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  void _listenToTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      try {
        await _apiService.post(
          '/update-fcm-token',
          data: {'fcm_token': newToken},
        );
        debugPrint('FCM token refreshed and registered');
      } catch (e) {
        debugPrint('Failed to register refreshed FCM token: $e');
      }
    });
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
