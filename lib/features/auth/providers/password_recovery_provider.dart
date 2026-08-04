import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../services/api_service.dart';

enum RecoveryStatus { initial, loading, success, error }

class PasswordRecoveryState {
  final RecoveryStatus status;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String> fieldErrors;

  const PasswordRecoveryState({
    this.status = RecoveryStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors = const {},
  });

  PasswordRecoveryState copyWith({
    RecoveryStatus? status,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
  }) {
    return PasswordRecoveryState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  bool get isLoading => status == RecoveryStatus.loading;
}

class PasswordRecoveryNotifier extends StateNotifier<PasswordRecoveryState> {
  PasswordRecoveryNotifier({
    ApiService? apiService,
    FlutterSecureStorage? secureStorage,
  }) : _apiService = apiService ?? ApiService(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       super(const PasswordRecoveryState());

  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  Future<bool> sendResetCode(String email) async {
    state = const PasswordRecoveryState(status: RecoveryStatus.loading);
    try {
      final response =
          await _apiService.post(
                '/auth/forgot-password',
                data: {'email': email},
                requiresAuth: false,
              )
              as Map<String, dynamic>;

      state = PasswordRecoveryState(
        status: RecoveryStatus.success,
        successMessage:
            response['message'] as String? ??
            'Si el correo existe en el sistema, recibirás un código para restablecer tu contraseña.',
      );
      return true;
    } on Failure catch (e) {
      state = _errorState(e);
      return false;
    } catch (_) {
      state = const PasswordRecoveryState(
        status: RecoveryStatus.error,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const PasswordRecoveryState(status: RecoveryStatus.loading);
    try {
      final response =
          await _apiService.post(
                '/auth/reset-password',
                data: {
                  'email': email,
                  'token': token,
                  'password': password,
                  'password_confirmation': passwordConfirmation,
                },
                requiresAuth: false,
              )
              as Map<String, dynamic>;

      await _discardLocalSession();

      state = PasswordRecoveryState(
        status: RecoveryStatus.success,
        successMessage:
            response['message'] as String? ??
            'Contraseña restablecida exitosamente. Inicia sesión con tu nueva contraseña.',
      );
      return true;
    } on Failure catch (e) {
      state = _errorState(e);
      return false;
    } catch (_) {
      state = const PasswordRecoveryState(
        status: RecoveryStatus.error,
        errorMessage: 'Error inesperado. Intenta de nuevo.',
      );
      return false;
    }
  }

  void reset() {
    state = const PasswordRecoveryState();
  }

  Future<void> _discardLocalSession() async {
    await _secureStorage.delete(key: AppConstants.jwtTokenKey);
    await Hive.box(AppConstants.authBox).clear();
  }

  PasswordRecoveryState _errorState(Failure failure) {
    if (failure is ServerFailure) {
      if (failure.statusCode == 429) {
        return const PasswordRecoveryState(
          status: RecoveryStatus.error,
          errorMessage:
              'Demasiados intentos. Espera un minuto e intenta de nuevo.',
        );
      }
      final fieldErrors = failure.fieldErrors?.map(
        (key, value) => MapEntry(key, value.first),
      );
      return PasswordRecoveryState(
        status: RecoveryStatus.error,
        errorMessage: failure.message,
        fieldErrors: fieldErrors ?? const {},
      );
    }
    return PasswordRecoveryState(
      status: RecoveryStatus.error,
      errorMessage: failure.message,
    );
  }
}

final passwordRecoveryProvider =
    StateNotifierProvider<PasswordRecoveryNotifier, PasswordRecoveryState>(
      (ref) => PasswordRecoveryNotifier(),
    );
