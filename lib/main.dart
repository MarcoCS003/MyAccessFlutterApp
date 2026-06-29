import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/providers/debug_role_provider.dart';
import 'features/notifications/models/notification_item.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.notificationsBox);

  final notification = NotificationItem.fromFcm(message.data);
  final box = Hive.box(AppConstants.notificationsBox);
  final items = box.get('items', defaultValue: <Map<dynamic, dynamic>>[]);
  items.insert(0, notification.toJson());
  await box.put('items', items);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM permissions and background handler registration.
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.childrenBox);
  await Hive.openBox(AppConstants.notificationsBox);
  await Hive.openBox(AppConstants.settingsBox);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFcmListeners();
  }

  void _setupFcmListeners() {
    // Foreground messages.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      ref.read(notificationProvider.notifier).addFromFcm(message.data);
    });

    // User tapped a notification while app was in background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateToNotifications();
    });

    // Check if app was opened from a terminated state via notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _navigateToNotifications();
      }
    });
  }

  void _navigateToNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      router.go('/notifications');
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'MyAccess IJL',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            // ignore: use_null_aware_elements
            if (child != null) child,
            const Positioned(
              bottom: 16,
              left: 16,
              child: DebugRoleToggleBtn(),
            ),
          ],
        );
      },
    );
  }
}

class DebugRoleToggleBtn extends ConsumerWidget {
  const DebugRoleToggleBtn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Solo mostrar el botón de debug si el usuario está autenticado
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    final debugRole = ref.watch(debugRoleProvider);
    final effectiveRole = debugRole ?? authState.user?.role ?? 'parent';
    final isParent = effectiveRole == 'parent';

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: InkWell(
          onTap: () {
            final nextRole = isParent ? 'teacher' : 'parent';
            ref.read(debugRoleProvider.notifier).state = nextRole;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Rol cambiado a: ${isParent ? "Docente" : "Tutor / Padre"}',
                  textAlign: TextAlign.center,
                ),
                duration: const Duration(seconds: 1),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.published_with_changes_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ver como: ${isParent ? "Docente" : "Tutor"}',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
