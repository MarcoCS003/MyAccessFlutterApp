import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/notifications/data/notification_local_store.dart';
import 'features/notifications/models/notification_item.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'firebase_options.dart';
import 'services/local_notifications_service.dart';

final _localNotifications = LocalNotificationsService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.authBox);
  await Hive.openBox(AppConstants.notificationsBox);

  // Persistir en la BD local con deduplicación; solo si es nuevo se muestra
  // la notificación del sistema (mensajes data-only no generan UI en bg).
  // Se escribe bajo la clave del usuario de la sesión guardada en auth_box;
  // sin sesión cae en el inbox anónimo fijo que la UI no lee.
  debugPrint('[FCM][BG] data: ${message.data}');
  final notification = NotificationItem.fromFcm(message.data);
  final inserted = await NotificationLocalStore.forCurrentUser().upsert(
    notification,
  );
  if (inserted) {
    final service = LocalNotificationsService();
    await service.init();
    await service.showAttendance(notification);
  }
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

  // Datos de locale para los DateFormat con 'es' (detalle del alumno).
  await initializeDateFormatting('es');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _localNotifications.init(onTap: _navigateToNotifications);
    _setupFcmListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a primer plano, recargar lo que el handler de background
    // escribió en Hive mientras la app estaba en segundo plano.
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).reloadFromLocal();
    }
  }

  void _setupFcmListeners() {
    // Foreground: persistir en BD local y mostrar notificación del sistema.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM][FG] data: ${message.data}');
      final notifier = ref.read(notificationProvider.notifier);
      final isNew = await notifier.addFromFcm(message.data);
      if (isNew) {
        await _localNotifications.showAttendance(
          NotificationItem.fromFcm(message.data),
        );
      }
    });

    // Usuario tocó una notificación con la app en background: persistir
    // (la deduplicación evita duplicar si el handler ya la guardó) y navegar.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM][TAP] data: ${message.data}');
      ref.read(notificationProvider.notifier).addFromFcm(message.data);
      _navigateToNotifications();
    });

    // App abierta desde terminada por una notificación.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('[FCM][INITIAL] data: ${message.data}');
        ref.read(notificationProvider.notifier).addFromFcm(message.data);
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
      title: 'Acceso IJL',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
