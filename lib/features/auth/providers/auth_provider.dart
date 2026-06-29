import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/auth_state.dart';
import '../models/user.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    GoogleSignIn? googleSignIn,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseMessaging? firebaseMessaging,
    FlutterSecureStorage? secureStorage,
    bool skipInitialCheck = false,
  })  : _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const AuthState()) {
    if (!skipInitialCheck) {
      checkAuthStatus();
    }
  }

  final GoogleSignIn _googleSignIn;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseMessaging _firebaseMessaging;
  final FlutterSecureStorage _secureStorage;

  Future<void> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading, errorMessage: null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUser =
          await _firebaseAuth.signInWithCredential(credential);
      final idToken = await firebaseUser.user?.getIdToken();

      if (idToken == null) {
        throw Exception('No se pudo obtener idToken de Firebase');
      }

      final fcmToken = await _firebaseMessaging.getToken();

      // TODO: Connect real backend endpoint /api/auth/google-login.
      // For now, simulate a successful backend response for development.
      await Future.delayed(const Duration(milliseconds: 800));
      debugPrint('FCM token available for backend: $fcmToken');

      // Simulated backend response for development.
      // Remove once /api/auth/google-login is connected.
      final simulatedUser = User(
        id: 1,
        name: googleUser.displayName ?? 'Usuario IJL',
        email: googleUser.email,
        avatar: googleUser.photoUrl,
        role: googleUser.email.contains('teacher') ||
                googleUser.email.contains('maestro')
            ? AppConstants.roleTeacher
            : AppConstants.roleParent,
      );

      await _persistSession(
        jwtToken: 'simulated_jwt_$idToken',
        user: simulatedUser,
      );

      state = AuthState(
        status: AuthStatus.authenticated,
        user: simulatedUser,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _firebaseAuthError(e),
      );
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _secureStorage.delete(key: AppConstants.jwtTokenKey);
      await Hive.box(AppConstants.authBox).clear();
      await Hive.box(AppConstants.childrenBox).clear();
      await Hive.box(AppConstants.notificationsBox).clear();
      await Hive.box(AppConstants.settingsBox).clear();
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
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

  String _firebaseAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Esta cuenta ya existe con otro método de inicio de sesión.';
      case 'invalid-credential':
        return 'Credencial inválida o expirada.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'operation-not-allowed':
        return 'Operación no permitida.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
