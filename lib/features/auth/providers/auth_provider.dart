import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/crash_report.dart';
import '../../../core/utils/user_key.dart';
import '../../../services/api_service.dart';
import '../data/session_store.dart';
import '../models/auth_state.dart';
import '../models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    FirebaseMessaging? firebaseMessaging,
    FlutterSecureStorage? secureStorage,
    ApiService? apiService,
    SessionStore? sessionStore,
    bool skipInitialCheck = false,
  }) : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _apiService = apiService ?? ApiService(),
       _sessionStore =
           sessionStore ?? SessionStore(secureStorage: secureStorage),
       super(const AuthState()) {
    if (!skipInitialCheck) {
      checkAuthStatus();
    }
  }

  final FirebaseMessaging _firebaseMessaging;
  final FlutterSecureStorage _secureStorage;
  final ApiService _apiService;
  final SessionStore _sessionStore;

  /// Identifica al usuario en Crashlytics con su ID interno (sin PII) y su
  /// rol. Con null limpia la identificación (logout / sin sesión).
  Future<void> _identifyCrashlyticsUser(User? user) async {
    if (user == null) {
      await crashSetUser('');
    } else {
      await crashSetUser('user_${user.id}');
      await crashSetRole(user.role);
    }
  }

  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
      crashLog('login_attempt');

      final fcmToken = await _getFcmTokenSafely();

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
      await _identifyCrashlyticsUser(user);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (e) {
      state = _errorState(e);
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

      final fcmToken = await _getFcmTokenSafely();

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
      await _identifyCrashlyticsUser(user);

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on Failure catch (e) {
      state = _errorState(e);
    } catch (e, st) {
      debugPrint('signUp falló: $e\n$st');
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Error al registrar. Verifica tus datos.',
      );
    }
  }

  /// Cambio de contraseña del usuario autenticado (flujo de cambio forzado
  /// de maestros). El JWT no cambia: solo se actualiza el user persistido
  /// (sesión activa + SessionStore) con mustChangePassword ya apagado.
  ///
  /// A diferencia de login/registro, los errores NO cambian el status:
  /// la sesión sigue activa y el guard del router debe mantener al usuario
  /// en /change-password (un 422 de validación no es un logout).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      crashLog('change_password_attempt');

      final response =
          await _apiService.post(
                '/auth/change-password',
                data: {
                  'current_password': currentPassword,
                  'password': newPassword,
                  'password_confirmation': confirmation,
                },
              )
              as Map<String, dynamic>;

      final user = User.fromJson(response['user'] as Map<String, dynamic>);

      final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
      final box = Hive.box(AppConstants.authBox);
      await box.put('user', user.toJson());
      if (token != null && token.isNotEmpty) {
        await _sessionStore.saveSession(user: user, jwt: token);
      }

      state = AuthState(status: AuthStatus.authenticated, user: user);
    } on ServerFailure catch (e) {
      debugPrint(
        'changePassword error ${e.statusCode}: ${e.message} '
        '| fieldErrors: ${e.fieldErrors}',
      );
      final fieldErrors = e.fieldErrors?.map(
        (key, value) => MapEntry(key, value.first),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: e.message,
        fieldErrors: fieldErrors ?? const {},
      );
    } on Failure catch (e) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: e.message,
      );
    } catch (e, st) {
      debugPrint('changePassword falló: $e\n$st');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: state.user,
        errorMessage: 'No se pudo cambiar la contraseña. Intenta de nuevo.',
      );
    }
  }

  AuthState _errorState(Failure failure) {
    if (failure is ServerFailure) {
      // Log temporal para depurar el 422 de producción en registro/login.
      debugPrint(
        'Auth error ${failure.statusCode}: ${failure.message} '
        '| fieldErrors: ${failure.fieldErrors}',
      );
      final fieldErrors = failure.fieldErrors?.map(
        (key, value) => MapEntry(key, value.first),
      );
      return AuthState(
        status: AuthStatus.error,
        errorMessage: failure.message,
        fieldErrors: fieldErrors ?? const {},
      );
    }
    return AuthState(status: AuthStatus.error, errorMessage: failure.message);
  }

  /// Cierra la sesión ACTIVA: elimina solo esa cuenta del dispositivo.
  ///
  /// - Si queda otra cuenta guardada, cambia automáticamente a ella
  ///   (auto-switch) y rota el token FCM: `deleteToken()` invalida el token
  ///   viejo (el backend limpia la cuenta eliminada al recibir UNREGISTERED)
  ///   y se registra uno nuevo para la cuenta restante.
  /// - Si era la última cuenta, limpia la sesión activa y borra el token
  ///   FCM para dejar de recibir pushes de esa cuenta en este dispositivo.
  ///
  /// Los datos namespacedos por userKey (notificaciones, hijos cacheados)
  /// se conservan por si la cuenta vuelve a iniciar sesión.
  Future<void> signOut() async {
    try {
      final user = state.user;
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      crashLog('logout');
      await _removeSessionInternal(userStorageKey(user.email));

      final remaining = _sessionStore.listSessions();
      if (remaining.isNotEmpty) {
        await _sessionStore.setActive(remaining.first.userKey);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: remaining.first.user,
        );
        await _registerFcmToken();
        await _identifyCrashlyticsUser(remaining.first.user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
        await _identifyCrashlyticsUser(null);
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Error al cerrar sesión: ${e.toString()}',
      );
    }
  }

  /// Elimina una cuenta guardada del dispositivo. Si es la activa, equivale
  /// a [signOut] (con auto-switch a la cuenta restante, si la hay).
  Future<void> removeAccount(String userKey) async {
    if (state.user != null && userStorageKey(state.user!.email) == userKey) {
      return signOut();
    }
    await _removeSessionInternal(userKey);
    // Fuerza reconstrucción de savedSessionsProvider.
    state = state.copyWith();
  }

  /// Elimina la sesión y rota el token FCM según las cuentas restantes.
  Future<void> _removeSessionInternal(String userKey) async {
    await _sessionStore.removeSession(userKey);
    if (_sessionStore.listSessions().isNotEmpty) {
      // Quedan cuentas: el token viejo (compartido con la cuenta eliminada)
      // se invalida y se genera uno nuevo; el caller lo re-registra con la
      // cuenta activa.
      await _deleteFcmTokenSafely();
    } else {
      await _sessionStore.clearActive();
      await _deleteFcmTokenSafely();
    }
  }

  /// Cambia la sesión activa a otra cuenta guardada, validando que su JWT
  /// siga vigente con GET /user. Devuelve true si el cambio se aplicó.
  ///
  /// - 401: el token expiró → se elimina la sesión y se restaura la cuenta
  ///   anterior (o se queda sin sesión si no había).
  /// - Error de red/servidor distinto: cambio optimista (soporte offline,
  ///   los datos namespacedos de la cuenta están en caché local).
  Future<bool> switchAccount(String userKey) async {
    final previousUser = state.user;
    final previousKey = previousUser != null
        ? userStorageKey(previousUser.email)
        : null;
    if (previousKey == userKey) return true;

    final activated = await _sessionStore.setActive(userKey);
    if (!activated) {
      state = state.copyWith(
        errorMessage: 'La cuenta ya no está disponible en este dispositivo',
      );
      return false;
    }

    final session = _sessionStore.listSessions().firstWhere(
      (s) => s.userKey == userKey,
    );

    try {
      await _apiService.get('/user');
    } on ServerFailure catch (e) {
      if (e.statusCode == 401) {
        await _sessionStore.removeSession(userKey);
        if (previousKey != null) {
          await _sessionStore.setActive(previousKey);
          state = AuthState(
            status: AuthStatus.authenticated,
            user: previousUser,
            errorMessage:
                'La sesión de esa cuenta expiró. Vuelve a iniciar sesión.',
          );
          await _identifyCrashlyticsUser(previousUser);
        } else {
          await _sessionStore.clearActive();
          state = const AuthState(
            status: AuthStatus.unauthenticated,
            errorMessage:
                'La sesión de esa cuenta expiró. Vuelve a iniciar sesión.',
          );
          await _identifyCrashlyticsUser(null);
        }
        return false;
      }
    } on Failure catch (_) {
      // Sin red u otro fallo no-auth: se aplica el cambio con datos en caché.
    }

    state = AuthState(status: AuthStatus.authenticated, user: session.user);
    await _identifyCrashlyticsUser(session.user);
    return true;
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
        // Migración: sesiones anteriores a multi-sesión no tienen entrada en
        // auth_box['sessions'] ni JWT por cuenta; se registran al arrancar.
        final userKey = userStorageKey(user.email);
        if (!_sessionStore.listSessions().any((s) => s.userKey == userKey)) {
          await _sessionStore.saveSession(user: user, jwt: token);
        }
        state = AuthState(status: AuthStatus.authenticated, user: user);
        await _identifyCrashlyticsUser(user);
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
    // Multi-sesión: agrega/actualiza la cuenta sin tocar las demás.
    await _sessionStore.saveSession(user: user, jwt: jwtToken);
  }

  Future<void> _registerFcmToken() async {
    try {
      final fcmToken = await _getFcmTokenSafely();
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

  /// Obtiene el FCM token sin romper el flujo de auth cuando no está
  /// disponible (en iOS sin entitlement de Push / APNs no configurado,
  /// getToken() lanza `apns-token-not-set`). El login/registro deben
  /// continuar aunque el dispositivo no pueda recibir push.
  Future<String?> _getFcmTokenSafely() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('FCM token no disponible (se continúa sin push): $e');
      return null;
    }
  }

  /// Invalida el token FCM del dispositivo (best-effort). El backend limpia
  /// `users.fcm_token` de las cuentas que lo tuvieran al recibir
  /// UNREGISTERED en el siguiente envío.
  Future<void> _deleteFcmTokenSafely() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('No se pudo eliminar el FCM token: $e');
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

/// Cuentas guardadas en el dispositivo (multi-sesión). Se relee cada vez
/// que cambia el estado de auth (login, logout, switch, removeAccount).
final savedSessionsProvider = Provider<List<SavedSession>>((ref) {
  ref.watch(authProvider);
  return SessionStore().listSessions();
});
