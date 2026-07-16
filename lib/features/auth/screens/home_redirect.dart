import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

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
        final role = authState.user?.role ?? 'parent';
        if (role == 'parent') {
          context.go('/parent-home');
        } else if (role == 'teacher') {
          context.go('/teacher-home');
        }
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
