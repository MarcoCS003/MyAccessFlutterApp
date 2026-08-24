import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'core/utils/crash_report.dart';
import 'core/utils/user_key.dart';
import 'core/widgets/app_error_widget.dart';
import 'features/auth/data/session_store.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/background/background_sync_register.dart';
import 'features/notifications/background/notification_sync_task.dart';
import 'features/notifications/data/notification_local_store.dart';
import 'features/notifications/data/notification_sync_service.dart';
import 'features/notifications/models/notification_item.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'firebase_options.dart';
import 'services/api_service.dart';
import 'services/local_notifications_service.dart';

final _localNotifications = LocalNotificationsService();

/// Envía el ACK de una notificación al backend en modo best-effort.
///
/// Extrae [notification_id] de [data], lo convierte a [int] y llama a
/// [NotificationSyncService.ack]. Cualquier error se loggea y nunca se
/// propaga. El [syncService] permite inyectar una instancia (útil en el
/// handler de background); si es null se crea una nueva.
void _ackBestEffort(
  Map<String, dynamic> data, {
  NotificationSyncService? syncService,
  String tag = '[FCM]',
}) {
  final rawId = data['notification_id'];
  if (rawId == null) return;

  final backendId = int.tryParse(rawId.toString());
  if (backendId == null) return;

  final service = syncService ?? NotificationSyncService();
  unawaited(
    service.ack(backendId).catchError((Object e) {
      debugPrint('$tag ACK error for $backendId: $e');
      return Future<void>.value();
    }),
  );
}

/// ACK best-effort autenticado con el JWT de la cuenta DUEÑA de la
/// notificación (no necesariamente la sesión activa). Si esa cuenta no
/// tiene JWT guardado, se omite el ACK.
Future<void> _ackForOwner(
  Map<String, dynamic> data,
  String ownerKey, {
  String tag = '[FCM]',
}) async {
  try {
    final jwt = await SessionStore().getJwt(ownerKey);
    if (jwt == null || jwt.isEmpty) return;
    _ackBestEffort(
      data,
      syncService: NotificationSyncService(api: ApiService(authToken: jwt)),
      tag: tag,
    );
  } catch (e) {
    debugPrint('$tag ACK setup error: $e');
  }
}

/// Resuelve la cuenta dueña de la notificación. null = descartar (el
/// usuario destinatario no tiene sesión en este dispositivo).
String? _routeNotification(NotificationItem notification) =>
    resolveUserKeyForNotification(
      recipientUserId: notification.recipientUserId,
      type: notification.type,
      studentId: notification.studentId,
    );

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  crashLog('fcm_received: type=${message.data['type']}');
  try {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.authBox);
    await Hive.openBox(AppConstants.childrenBox);
    await Hive.openBox(AppConstants.notificationsBox);

    // Persistir en la BD local con deduplicación; solo si es nuevo se muestra
    // la notificación del sistema (mensajes data-only no generan UI en bg).
    // Multi-sesión: se enruta al inbox de la cuenta a la que pertenece el
    // mensaje (por user_id; payloads viejos usan el ruteo legado). Si el
    // usuario destinatario no tiene sesión en el dispositivo, se descarta.
    debugPrint('[FCM][BG] data: ${message.data}');
    final notification = NotificationItem.fromFcm(message.data);
    final targetKey = _routeNotification(notification);
    if (targetKey == null) {
      final known = SessionStore()
          .listSessions()
          .map((s) => '${s.userKey}#${s.user.id}')
          .toList();
      debugPrint(
        '[FCM][BG] descartada: user_id ${notification.recipientUserId} '
        'sin sesión en el dispositivo (sesiones: $known)',
      );
      return;
    }
    final inserted = await NotificationLocalStore(
      userKey: targetKey,
    ).upsert(notification);
    if (inserted) {
      final service = LocalNotificationsService();
      await service.init();
      await service.showAttendance(notification);
    }

    // ACK best-effort con el JWT de la cuenta dueña.
    await _ackForOwner(message.data, targetKey, tag: '[FCM][BG]');
  } catch (e, st) {
    // El handler corre en un isolate de background: cualquier fallo se
    // reporta a Crashlytics y nunca se propaga.
    crashRecordError(e, st);
    debugPrint('[FCM][BG] unhandled error: $e\n$st');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: captura global de errores. El orden importa: Firebase
  // primero, luego los handlers, y TODO el resto del init dentro de la
  // zona protegida.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  ErrorWidget.builder = appErrorBuilder;

  await runZonedGuarded(
    () async {
      // FCM permissions and background handler registration.
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      await Hive.initFlutter();
      await Hive.openBox(AppConstants.authBox);
      await Hive.openBox(AppConstants.childrenBox);
      await Hive.openBox(AppConstants.notificationsBox);
      await Hive.openBox(AppConstants.settingsBox);

      // Registrar tarea periódica de sincronización de notificaciones pendientes.
      await registerBackgroundSync();

      // Sync de respaldo al abrir la app si la última sincronización fue hace
      // más de 12 horas. Es especialmente útil en iOS donde background_fetch no
      // garantiza ejecución periódica.
      unawaited(maybeSyncOnAppOpen());

      // Datos de locale para los DateFormat con 'es' (detalle del alumno).
      await initializeDateFormatting('es');

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
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
    // escribió en Hive mientras la app estaba en segundo plano. El handler
    // corre en otro isolate con su propia instancia de Hive: reloadFromLocal
    // reabre el box para releer desde disco.
    if (state == AppLifecycleState.resumed) {
      ref.read(notificationProvider.notifier).reloadFromLocal();
    }
  }

  /// Persiste la notificación en el inbox de la cuenta a la que pertenece
  /// (multi-sesión). Si es de la sesión activa pasa por el provider para
  /// actualizar la UI en caliente; si es de otra cuenta guardada, escribe
  /// directo en Hive sin tocar el estado en memoria.
  ///
  /// Devuelve true si era nueva; false si era duplicada; null si se
  /// descartó (el usuario destinatario no tiene sesión en el dispositivo).
  Future<bool?> _persistRouted(NotificationItem notification) async {
    final targetKey = _routeNotification(notification);
    if (targetKey == null) {
      final known = SessionStore()
          .listSessions()
          .map((s) => '${s.userKey}#${s.user.id}')
          .toList();
      debugPrint(
        '[FCM] descartada: user_id ${notification.recipientUserId} '
        'sin sesión en el dispositivo (sesiones: $known)',
      );
      return null;
    }
    final activeEmail = ref.read(authProvider).user?.email;
    if (activeEmail != null && userStorageKey(activeEmail) == targetKey) {
      return ref
          .read(notificationProvider.notifier)
          .addNotification(notification);
    }
    return NotificationLocalStore(userKey: targetKey).upsert(notification);
  }

  void _setupFcmListeners() {
    // Foreground: persistir en BD local y mostrar notificación del sistema.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('[FCM][FG] data: ${message.data}');
      crashLog('fcm_received: type=${message.data['type']}');
      final notification = NotificationItem.fromFcm(message.data);
      final isNew = await _persistRouted(notification);
      // Descartada (usuario sin sesión aquí): sin bandeja ni ACK.
      if (isNew == null) return;
      if (isNew) {
        await _localNotifications.showAttendance(notification);
      }
      final ownerKey = _routeNotification(notification);
      if (ownerKey != null) {
        await _ackForOwner(message.data, ownerKey, tag: '[FCM][FG]');
      }
    });

    // Usuario tocó una notificación con la app en background: persistir
    // (la deduplicación evita duplicar si el handler ya la guardó) y navegar.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('[FCM][TAP] data: ${message.data}');
      crashLog('fcm_received: type=${message.data['type']}');
      final notification = NotificationItem.fromFcm(message.data);
      final isNew = await _persistRouted(notification);
      if (isNew != null) {
        final ownerKey = _routeNotification(notification);
        if (ownerKey != null) {
          await _ackForOwner(message.data, ownerKey, tag: '[FCM][TAP]');
        }
      }
      _navigateToNotifications();
    });

    // App abierta desde terminada por una notificación.
    FirebaseMessaging.instance.getInitialMessage().then((message) async {
      if (message != null) {
        debugPrint('[FCM][INITIAL] data: ${message.data}');
        crashLog('fcm_received: type=${message.data['type']}');
        final notification = NotificationItem.fromFcm(message.data);
        final isNew = await _persistRouted(notification);
        if (isNew != null) {
          final ownerKey = _routeNotification(notification);
          if (ownerKey != null) {
            await _ackForOwner(message.data, ownerKey, tag: '[FCM][INITIAL]');
          }
        }
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
