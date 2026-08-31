import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../models/user.dart';

class HomeRedirect extends ConsumerStatefulWidget {
  const HomeRedirect({super.key});

  @override
  ConsumerState<HomeRedirect> createState() => _HomeRedirectState();
}

class _HomeRedirectState extends ConsumerState<HomeRedirect> {
  @override
  void initState() {
    super.initState();
    _performRedirect();
  }

  void _performRedirect() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        final user = authState.user;
        if (user?.mustChangePassword == true) {
          context.go('/change-password');
          return;
        }
        final role = user?.role ?? 'parent';
        if (role == 'parent') {
          context.go('/parent-home');
        } else if (staffRoles.contains(role)) {
          context.go('/teacher-home');
        }
        // student/user se ignoran: sin redirección (comportamiento previo).
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el estado para disparar la redirección si el rol cambia en caliente
    ref.listen(authProvider, (previous, next) {
      _performRedirect();
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
