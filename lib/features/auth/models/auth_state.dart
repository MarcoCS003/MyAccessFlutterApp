import 'user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final Map<String, String> fieldErrors;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    Map<String, String>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? const {},
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isTeacher => user?.isTeacher ?? false;
  bool get isParent => user?.isParent ?? false;
}
