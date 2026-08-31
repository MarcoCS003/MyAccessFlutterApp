import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/change_password_screen.dart';
import '../../features/padres/screens/link_child_screen.dart';
import '../../features/padres/screens/link_child_confirm_screen.dart';
import '../../features/padres/screens/child_detail_screen.dart';
import '../../features/padres/screens/child_qr_screen.dart';
import '../../features/maestros/screens/teacher_qr_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/home/screens/main_navigation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // El GoRouter se crea UNA sola vez: recrearlo en cada cambio de auth
  // reinicia el stack de navegación y pierde el estado de las pantallas
  // (p.ej. los TextFields del login al fallar las credenciales). El
  // redirect se re-evalúa vía refreshListenable cuando cambia auth.
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);
  ref.listen(authProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/reset-password';

      if (!authState.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // Cambio de contraseña forzado: mientras el flag esté encendido, la
      // única ruta permitida es /change-password (bloquea homes, perfil,
      // rutas de auth, etc.).
      if (authState.user?.mustChangePassword == true) {
        return state.matchedLocation == '/change-password'
            ? null
            : '/change-password';
      }

      if (isAuthRoute) {
        // Alta de cuenta adicional desde Perfil: un usuario autenticado
        // puede entrar a /login solo en modo addAccount.
        final isAddAccount =
            state.matchedLocation == '/login' &&
            state.uri.queryParameters['addAccount'] == '1';
        return isAddAccount ? null : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/parent-home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/link-child',
        builder: (context, state) => const LinkChildScreen(),
      ),
      GoRoute(
        path: '/link-child/confirm',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return LinkChildConfirmScreen(code: code, id: id);
        },
      ),
      GoRoute(
        path: '/child/:id',
        builder: (context, state) {
          final childId = state.pathParameters['id'] ?? '';
          return ChildDetailScreen(childId: childId);
        },
        routes: [
          GoRoute(
            path: 'qr',
            builder: (context, state) {
              final childId = state.pathParameters['id'] ?? '';
              return ChildQrScreen(childId: childId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/teacher-home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/qr',
        builder: (context, state) => const TeacherQRScreen(),
      ),
      GoRoute(
        path: '/teacher-qr',
        builder: (context, state) => const TeacherQRScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
