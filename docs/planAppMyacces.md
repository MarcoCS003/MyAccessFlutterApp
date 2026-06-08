# My Access IJL App - Plan de Implementación

Este documento detalla el plan paso a paso para implementar la app Flutter **My Access IJL** en la máquina de la escuela con mejores recursos.

---

## Fase 0: Preparación del Entorno (Día 1)

### 0.1 Requisitos del Sistema

| Requisito | Especificación |
|-----------|----------------|
| **Sistema operativo** | Windows 10/11, macOS 12+, o Linux (Ubuntu 22.04 LTS recomendado) |
| **Procesador** | Multi-core (mínimo 4 núcleos, 8+ recomendado) |
| **RAM** | Mínimo 8 GB, **16 GB recomendado** |
| **Disco** | SSD con al menos 20 GB libres |
| **Internet** | Estable para descargar dependencias y Firebase |

### 0.2 Instalación de Herramientas Base

```bash
# 1. Instalar Flutter SDK (versión estable 3.24.x o superior)
# Descargar desde: https://docs.flutter.dev/get-started/install
# Extraer a C:\flutter (Windows) o ~/development/flutter (Linux/Mac)

# 2. Agregar Flutter al PATH
export PATH="$PATH:/ruta/a/flutter/bin"

# 3. Verificar instalación
flutter doctor

# 4. Instalar Android Studio o IntelliJ IDEA
# - Instalar plugins: Flutter y Dart

# 5. Instalar Android SDK con CLI
flutter config --android-sdk /ruta/a/android-sdk
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 6. Instalar VS Code (opcional pero recomendado)
# Extensiones: Flutter, Dart, Awesome Flutter Snippets, Error Lens

# 7. Instalar Git
# Verificar: git --version
```

### 0.3 Configuración de Firebase

```bash
# 1. Instalar Firebase CLI
curl -sL https://firebase.tools | bash

# 2. Iniciar sesión en Firebase
firebase login

# 3. Instalar FlutterFire CLI
dart pub global activate flutterfire_cli
```

---

## Fase 1: Creación del Proyecto y Configuración Firebase (Día 1-2)

### 1.1 Crear Proyecto Flutter

```bash
# Crear proyecto
flutter create --org com.ijl.myaccess myaccess_ijl_app

cd myaccess_ijl_app

# Verificar que compile
flutter run
```

### 1.2 Crear Proyecto en Firebase Console

1. Ir a https://console.firebase.google.com/
2. Crear nuevo proyecto: `My Access IJL`
3. Habilitar **Google Analytics** (opcional pero recomendado)
4. En **Project Settings** > **General**, anotar:
   - Project ID
   - Web API Key
   - App ID (después de registrar apps)

### 1.3 Registrar Apps en Firebase

#### Android
1. Firebase Console > Project Settings > Add App > Android
2. **Package name:** `com.ijl.myaccess`
3. **SHA-1:** Obtener con:
   ```bash
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore
   # Password por defecto: android
   ```
4. Descargar `google-services.json` y colocar en `android/app/`

#### iOS
1. Firebase Console > Project Settings > Add App > iOS
2. **Bundle ID:** `com.ijl.myaccess`
3. Descargar `GoogleService-Info.plist` y colocar en `ios/Runner/` con Xcode

### 1.4 Configurar Firebase en Flutter

```bash
# En la raíz del proyecto Flutter
flutterfire configure \
  --project=notificacionesapptutores \
  --out=lib/firebase_options.dart \
  --platforms=android,ios
```

### 1.5 Instalar Dependencias

Editar `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  firebase_messaging: ^15.1.3
  google_sign_in: ^6.2.1
  
  # Estado y navegación
  flutter_riverpod: ^2.5.1
  go_router: ^14.3.0
  
  # HTTP
  dio: ^5.7.0
  retrofit: ^4.4.0
  
  # Almacenamiento
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.2
  
  # QR
  mobile_scanner: ^5.2.1
  qr_flutter: ^4.1.0
  
  # UI y utilidades
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10
  intl: ^0.19.0
  shimmer: ^3.0.0
  cached_network_image: ^3.4.1
  package_info_plus: ^8.0.2
  
  # Code generation annotations
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.12
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  retrofit_generator: ^9.1.0
  hive_generator: ^2.0.1
```

```bash
flutter pub get
```

### 1.6 Configurar Plataformas Nativas

#### Android (`android/app/build.gradle`)

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace = "com.ijl.myaccess"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.ijl.myaccess"
        minSdk = 23  // Firebase Auth requiere mínimo 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }
}
```

#### Android (`android/build.gradle`)

```gradle
plugins {
    id "com.google.gms.google-services" version "4.4.2" apply false
}
```

#### iOS (`ios/Podfile`)

```ruby
platform :ios, '13.0'

# ... resto del archivo
```

Después de editar:
```bash
cd ios && pod install --repo-update && cd ..
```

---

## Fase 2: Arquitectura Base y Modelos (Día 2-3)

### 2.1 Estructura de Carpetas

```bash
cd lib

mkdir -p config core/errors core/extensions core/utils
mkdir -p data/models data/datasources/remote data/datasources/local data/repositories
mkdir -p domain/entities domain/repositories domain/usecases
mkdir -p presentation/providers presentation/screens/splash presentation/screens/auth presentation/screens/home presentation/screens/children presentation/screens/teacher presentation/screens/notifications presentation/screens/profile presentation/widgets presentation/components
mkdir -p services generated
```

### 2.2 Configurar Tema (`lib/config/theme.dart`)

Implementar `ThemeData` para light y dark mode usando los colores institucionales definidos en `diseño.md`.

### 2.3 Configurar Router (`lib/config/router.dart`)

Implementar `GoRouter` con rutas:
- `/splash`
- `/login`
- `/onboarding`
- `/home`
- `/link-child`
- `/child/:id`
- `/child/:id/qr`
- `/teacher/qr`
- `/notifications`
- `/profile`

### 2.4 Crear Modelos de Datos

```bash
# Crear archivos:
# lib/data/models/user_model.dart
# lib/data/models/student_model.dart
# lib/data/models/attendance_model.dart
# lib/data/models/notification_model.dart
```

Cada modelo debe usar `freezed` + `json_serializable`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    required String name,
    required String email,
    required String role,
    String? fcmToken,
    int? teacherId,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
```

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.5 Configurar Hive

```dart
// lib/data/datasources/local/hive_service.dart
// Boxes: 'user', 'students', 'notifications', 'settings'
```

---

## Fase 3: Autenticación con Google (Día 3-4)

### 3.1 Implementar Firebase Auth Service

```dart
// lib/services/firebase_auth_service.dart

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
```

### 3.2 Implementar API Service con Retrofit

```dart
// lib/data/datasources/remote/api_service.dart

import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: "https://chechador.ijl.com.mx/api")
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST("/auth/google-login")
  Future<AuthResponse> googleLogin(@Body() GoogleLoginRequest request);

  @GET("/user")
  Future<UserModel> getUser();

  @POST("/vincular-alumno")
  Future<MessageResponse> linkChild(@Body() LinkChildRequest request);

  @POST("/desvincular-alumno")
  Future<MessageResponse> unlinkChild(@Body() UnlinkChildRequest request);

  @GET("/students/{id}/attendances")
  Future<List<AttendanceModel>> getStudentAttendances(@Path("id") int id);

  @POST("/update-fcm-token")
  Future<MessageResponse> updateFcmToken(@Body() FcmTokenRequest request);
}
```

### 3.3 Configurar Dio con Interceptores

```dart
// lib/data/datasources/remote/dio_client.dart

Dio createDio() {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://chechador.ijl.com.mx/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await SecureStorage().read('access_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Redirigir a login
      }
      return handler.next(error);
    },
  ));

  return dio;
}
```

### 3.4 Implementar Auth Repository y Provider

```dart
// lib/data/repositories/auth_repository.dart
// lib/presentation/providers/auth_provider.dart
```

Flujo:
1. `signInWithGoogle()` → Firebase Auth
2. Obtener `idToken`
3. Obtener `fcmToken` de Firebase Messaging
4. POST `/api/auth/google-login` con ambos tokens
5. Guardar `access_token` en `flutter_secure_storage`
6. Guardar `user` en Hive
7. Navegar a Home o Onboarding

### 3.5 Crear Login Screen UI

Implementar diseño de `promptStich.md` - Pantalla 2 (Login Screen).

---

## Fase 4: FCM - Notificaciones Push (Día 4-5)

### 4.1 Configurar Firebase Messaging

```dart
// lib/services/firebase_messaging_service.dart

class FirebaseMessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token refresh
    _messaging.onTokenRefresh.listen((token) async {
      await _updateTokenOnServer(token);
    });

    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated tap
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Guardar en Hive
    // Mostrar local notification o banner
    // Actualizar badge
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navegar a ChildDetailScreen con message.data['student_id']
  }
}
```

### 4.2 Configurar Local Notifications (opcional pero recomendado)

Para mostrar notificación cuando app está en foreground:

```yaml
# Agregar a pubspec.yaml
flutter_local_notifications: ^17.2.3
```

### 4.3 Crear Notification Repository y Provider

```dart
// Guardar notificaciones en Hive
// Contador de no leídas
// Marcar como leída
```

---

## Fase 5: Funcionalidad de Padres (Día 5-7)

### 5.1 Onboarding Screen (primera vez)

- Mostrar solo si `isFirstTime == true` en Hive
- 3 slides explicativos
- Botón "Comenzar" guarda flag y navega a Home

### 5.2 Link Child Screen (Vincular Hijo)

Implementar escáner QR con `mobile_scanner`:

```dart
MobileScanner(
  onDetect: (capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        _linkChild(code);
      }
    }
  },
)
```

Flujo:
1. Escanear QR o ingresar código manual
2. POST `/api/vincular-alumno` con `{codigo_alumno: code}`
3. Mostrar confirmación con datos del alumno
4. Actualizar lista de hijos en provider

### 5.3 Home Screen (Padre)

- Consumir `authProvider.user` para obtener `students`
- Lista de tarjetas de hijos vinculados
- Pull-to-refresh
- Navegar a `ChildDetailScreen` al tocar tarjeta
- FAB o AppBar action para "+ Vincular hijo"

### 5.4 Child Detail Screen

- Header con info del alumno
- Tabs: Hoy / Semana / Mes
- Timeline vertical de asistencia
- GET `/api/students/{id}/attendances`
- Cache en Hive para offline

### 5.5 Child QR Screen

- Mostrar QR del hijo grande y centrado
- Usar `qr_flutter` para generar QR desde `student.qrCode`
- Botón para aumentar brillo automáticamente

---

## Fase 6: Funcionalidad de Maestros (Día 7-8)

### 6.1 Home Screen (Maestro)

- Detectar `role == 'teacher'`
- Mostrar info del maestro desde `user.teacherId`
- Card con QR propio grande
- Stats de asistencia
- Timeline del día

### 6.2 Teacher QR Screen

- Similar a Child QR pero para el maestro
- GET `/api/teachers` o usar datos locales del maestro vinculado
- Badge "MAESTRO"

---

## Fase 7: Notificaciones y Perfil (Día 8-9)

### 7.1 Notifications Screen

- Lista de notificaciones desde Hive
- Agrupadas por fecha
- Swipe to dismiss
- Badge en BottomNav
- Marcar todo como leído

### 7.2 Profile Screen

- Info de Google (foto, nombre, email)
- Toggle notificaciones
- Toggle tema (claro/oscuro/sistema)
- Versión de app
- Cerrar sesión (limpiar Hive + SecureStorage + Firebase signOut)

---

## Fase 8: Testing y Ajustes (Día 9-10)

### 8.1 Testing en Dispositivo Real

```bash
# Conectar dispositivo Android
flutter devices

# Instalar debug
flutter run --release

# Para iOS (requiere Mac + Xcode + certificado de desarrollador)
flutter run --release
```

### 8.2 Checklist de Pruebas

- [ ] Login con Google funciona en Android
- [ ] Login con Google funciona en iOS
- [ ] FCM token se envía al backend
- [ ] Vincular hijo por QR funciona
- [ ] Vincular hijo por código manual funciona
- [ ] Notificación push se recibe en foreground
- [ ] Notificación push se recibe en background
- [ ] Tocar notificación abre detalle del hijo
- [ ] Historial de asistencia se carga y guarda offline
- [ ] QR de hijo se muestra correctamente
- [ ] QR de maestro se muestra correctamente
- [ ] Cerrar sesión limpia todo
- [ ] Tema claro/oscuro funciona
- [ ] App funciona offline con datos cacheados

### 8.3 Optimización de Rendimiento

```bash
# Analizar tamaño del app
flutter build apk --analyze-size

# Construir release APK
flutter build apk --release

# Construir App Bundle (para Play Store)
flutter build appbundle --release

# Construir iOS (requiere Mac)
flutter build ios --release
```

---

## Fase 9: Preparación para Producción (Día 10-11)

### 9.1 Configurar ProGuard (Android)

```proguard
# android/app/proguard-rules.pro
-keep class com.ijl.myaccess.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class com.google.firebase.** { *; }
```

### 9.2 Firmar APK/AAB

```bash
# Generar keystore (una sola vez)
keytool -genkey -v -keystore ~/myaccess-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias myaccess

# Configurar en android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=myaccess
storeFile=/ruta/a/myaccess-keystore.jks
```

### 9.3 Splash Screen Nativo

```bash
flutter pub add flutter_native_splash
```

Configurar en `pubspec.yaml`:

```yaml
flutter_native_splash:
  color: "#1B3A6B"
  image: assets/images/logo_splash.png
  android: true
  ios: true
```

```bash
flutter pub run flutter_native_splash:create
```

### 9.4 Icono de App

```bash
flutter pub add flutter_launcher_icons
```

Configurar en `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/images/app_icon.png"
  min_sdk_android: 23
```

```bash
flutter pub run flutter_launcher_icons
```

---

## Fase 10: Documentación Final y Handoff (Día 11-12)

### 10.1 README del Proyecto Flutter

Crear `README.md` con:
- Descripción del proyecto
- Requisitos
- Instalación paso a paso
- Estructura de carpetas
- Cómo correr
- Cómo build para release
- Variables de entorno necesarias

### 10.2 Variables de Entorno

Crear `.env.example`:

```
API_BASE_URL=https://chechador.ijl.com.mx/api
FIREBASE_PROJECT_ID=notificacionesapptutores
```

### 10.3 Subir a Repositorio Git

```bash
git init
git add .
git commit -m "feat: initial commit My Access IJL Flutter app"
git branch -M main
git remote add origin <url-del-repo>
git push -u origin main
```

---

## Recursos Adicionales

### Comandos Útiles

```bash
# Limpiar y rebuild
flutter clean && flutter pub get

# Generar código (freezed, retrofit, etc)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode para development
flutter pub run build_runner watch --delete-conflicting-outputs

# Analizar código
flutter analyze

# Formatear código
flutter format lib/

# Correr con hot reload
flutter run

# Correr en modo profile (rendimiento)
flutter run --profile

# Correr tests
flutter test
```

### Dependencias del Backend (PR necesario)

Antes de que la app funcione completamente, el backend necesita:

1. **Nuevo endpoint:** `POST /api/auth/google-login`
2. **Modificar observer:** Enviar FCM a `users` vinculados en `student_user`
3. **Nuevo endpoint:** `POST /api/desvincular-alumno`
4. **Nuevo endpoint:** `GET /api/students/{id}/attendances`

### Contactos y Soporte

- **Backend:** Equipo Laravel del Instituto Juárez Lincoln
- **Firebase Console:** Cuenta del proyecto escolar
- **App Store / Play Store:** Cuentas de desarrollador de la institución

---

## Timeline Resumido

| Día | Fase | Tareas |
|-----|------|--------|
| 1 | 0-1 | Instalar entorno, crear proyecto Flutter, configurar Firebase |
| 2 | 1-2 | Configurar plataformas nativas, instalar dependencias, crear modelos |
| 3 | 2 | Implementar tema, router, estructura de carpetas |
| 4 | 3 | Autenticación con Google, login screen |
| 5 | 4 | FCM, notificaciones push, local notifications |
| 6 | 5 | Onboarding, vincular hijo (QR + manual) |
| 7 | 5 | Home padre, lista de hijos, detalle de hijo |
| 8 | 5-6 | QR de hijo, home maestro, QR de maestro |
| 9 | 7 | Centro de notificaciones, perfil y ajustes |
| 10 | 8 | Testing en dispositivo real, corrección de bugs |
| 11 | 9 | Firma, splash nativo, icono, builds de release |
| 12 | 10 | Documentación, README, subir a Git |

**Total estimado: 10-12 días de trabajo efectivo.**
