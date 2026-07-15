import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  runApp(const ProviderScope(child: MyApp()));
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
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
