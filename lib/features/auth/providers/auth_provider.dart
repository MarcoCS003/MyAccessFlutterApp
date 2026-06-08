import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockUser {
  final String name;
  final String email;
  final String photoUrl;

  const MockUser({
    required this.name,
    required this.email,
    required this.photoUrl,
  });
}

class AuthState {
  final bool isAuthenticated;
  final String role; // 'parent' o 'teacher'
  final MockUser? user;

  const AuthState({
    required this.isAuthenticated,
    required this.role,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? role,
    MockUser? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier()
      : super(const AuthState(
          isAuthenticated: false,
          role: 'parent', // Rol inicial por defecto
          user: null,
        ));

  void login() {
    state = state.copyWith(
      isAuthenticated: true,
      user: const MockUser(
        name: 'Juan Pérez IJL',
        email: 'juan.perez@ijl.edu.mx',
        photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
      ),
    );
  }

  void logout() {
    state = const AuthState(
      isAuthenticated: false,
      role: 'parent',
      user: null,
    );
  }

  void toggleRole() {
    final newRole = state.role == 'parent' ? 'teacher' : 'parent';
    MockUser? newUser = state.user;
    if (state.isAuthenticated) {
      if (newRole == 'teacher') {
        newUser = const MockUser(
          name: 'Prof. Carlos Ortega',
          email: 'carlos.ortega@ijl.edu.mx',
          photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&w=150&q=80',
        );
      } else {
        newUser = const MockUser(
          name: 'Juan Pérez IJL',
          email: 'juan.perez@ijl.edu.mx',
          photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
        );
      }
    }
    state = state.copyWith(
      role: newRole,
      user: newUser,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
