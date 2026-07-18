import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/padres/screens/link_child_screen.dart';
import '../../features/padres/screens/link_child_confirm_screen.dart';
import '../../features/padres/screens/child_detail_screen.dart';
import '../../features/padres/screens/child_qr_screen.dart';
import '../../features/maestros/screens/teacher_qr_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/home/screens/main_navigation_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!authState.isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthRoute) {
        return '/home';
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
