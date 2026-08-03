# MyAccess IJL — Cliente Flutter

Aplicación móvil Flutter para **MyAccess IJL**, el sistema de control de acceso escolar. Permite a padres y maestros recibir notificaciones en tiempo real (FCM) sobre las entradas y salidas de los alumnos, consultar historiales de asistencia y gestionar el acceso mediante códigos QR.

## Características

- **Autenticación** de usuarios (actualmente mock, con cambio de rol padre/maestro en modo debug).
- **Notificaciones push (FCM)** de entradas y salidas de alumnos, persistidas localmente en Hive (bandeja del sistema vía `flutter_local_notifications`).
- **Home de padres**: estado de los hijos vinculados, detalle por alumno con timeline e historial de asistencia.
- **Home de maestros**: vista de asistencia propia.
- **QR**: generación y escaneo de códigos QR para control de acceso (`qr_flutter`, `mobile_scanner`).
- **Vinculación de hijos** (`/link-child`).
- **Perfil de usuario** y ajustes.

## Stack técnico

- **Flutter SDK** `^3.12.0` (canal stable)
- **Estado:** Riverpod (`flutter_riverpod`)
- **Navegación:** GoRouter (`lib/core/router/router.dart`) — nunca usar `Navigator.push` directamente
- **Backend:** API Laravel vía Dio (`lib/services/api_service.dart`). La URL base se configura **únicamente** en `lib/core/constants/api_config.dart`
- **Firebase:** proyecto `notificacionesapptutores` (`firebase_core`, `firebase_messaging`)
- **Almacenamiento local:** Hive (`notifications_box`), `flutter_secure_storage`
- **UI:** Material 3 con paleta IJL (`lib/core/theme/theme.dart`), Google Fonts (Poppins/Inter)

## Estructura del proyecto

```
lib/
├── core/          # router, theme, constants (api_config), errors
├── features/      # auth, home, padres, maestros, notifications, profile
├── services/      # api_service (Dio), local_notifications_service
├── firebase_options.dart
└── main.dart
```

La estructura sigue Clean Architecture, aunque las capas `data/` y `domain/` están mayormente como stubs por ahora.

## Configuración

1. Instala dependencias:

   ```bash
   flutter pub get
   ```

2. Configura la URL del backend en `lib/core/constants/api_config.dart`:
   - Emulador Android: `10.0.2.2`
   - Dispositivo físico: `192.168.20.206`
   - Si el backend corre en otra máquina/puerto, usa `adb reverse tcp:8000 tcp:8000` para el emulador.

   > ⚠️ El backend Laravel es un proyecto aparte (`myAccessIJL`) administrado por el usuario. No modificarlo desde este repo.

3. Firebase ya viene configurado (`google-services.json` en Android, `GoogleService-Info.plist` en iOS). Para builds de iOS/macOS ver `docs/EJECUCION_MAC.md`.

## Comandos de desarrollo

```bash
flutter pub get                 # instalar dependencias
flutter run                     # ejecutar en debug
flutter test                    # correr todos los tests
flutter test test/widget_test.dart  # un solo test
flutter analyze                 # análisis estático
dart format lib/ test/          # formatear código
flutter build apk --debug       # APK debug
flutter build apk --release     # APK release
```

No se requiere generación de código: `build_runner` está en dev_dependencies pero `freezed`, `json_serializable`, `retrofit` y `hive_generator` están comentados en `pubspec.yaml`.

## Notas para desarrollo

- **Notificaciones FCM:** cada mensaje se persiste en Hive (`lib/features/notifications/data/notification_local_store.dart`) con deduplicación por ID. El payload real del backend usa `attendance_type: entry|exit` y `recorded_at` (ver `docs/reporte_notificaciones_fcm.md`). El estado/timeline de cada alumno se deriva de la base local, no de llamadas extra al backend.
- **Ruta inicial:** `/login`; usuarios autenticados redirigen a `/home`.
- **Debug:** hay un botón flotante `DebugRoleToggleBtn` (esquina inferior izquierda) para alternar entre rol padre y maestro sin re-login. Además, en `kDebugMode` se siembra un mes de notificaciones demo por usuario al montar la navegación principal (`NotificationSeeder`).
- **Android:** JVM 17, package `com.jmoreno.riverboldbrave`, desugaring habilitado (requerido por `flutter_local_notifications`).
- **Tests:** los widget tests deben envolver la app en `ProviderScope(child: MyApp())`.

## Documentación adicional

- `docs/planAppMyacces.md` — plan de implementación
- `docs/diseño.md` — especificación UI/UX
- `docs/reporte_notificaciones_fcm.md` — formato real de los mensajes FCM
- `docs/EJECUCION_MAC.md` — pasos para compilar en macOS/iOS
- `AGENTS.md` — guía compacta del proyecto para agentes de IA
