# My Access IJL App - Documento de Diseño

## 1. Visión General

**My Access IJL App** es la aplicación móvil oficial del Instituto Juárez Lincoln para padres de familia y maestros. Permite recibir notificaciones en tiempo real cuando los alumnos o maestros registran su entrada/salida en los checadores de la escuela.

- **Plataformas:** iOS y Android
- **Framework:** Flutter 3.x
- **Backend:** Laravel 12 (API REST + Sanctum)
- **Autenticación:** Firebase Authentication (Google Sign-In)
- **Notificaciones:** Firebase Cloud Messaging (FCM)
- **Base de datos local:** Hive / SQLite (notificaciones offline)

## 2. Tipos de Usuario

| Tipo | Descripción | Funcionalidades |
|------|-------------|-----------------|
| **Padre** | Cualquier cuenta de Google. Se vincula a sus hijos escaneando el QR del alumno. | Login con Google, vincular/desvincular hijos, recibir notificaciones push FCM, ver historial de asistencia de hijos, ver QR de hijos, configuración. |
| **Maestro** | Cuenta de Google Workspace de la escuela (detectada en BD). | Login con Google, ver su propio QR de acceso, recibir notificaciones push, historial de su asistencia, configuración. |

## 3. Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    My Access IJL App                        │
│                      (Flutter)                              │
├─────────────────────────────────────────────────────────────┤
│  UI Layer           │  State Management (Riverpod)          │
│  - Screens          │  - AuthNotifier                       │
│  - Widgets          │  - StudentNotifier                    │
│  - Components       │  - NotificationNotifier               │
├─────────────────────────────────────────────────────────────┤
│  Domain Layer       │  Data Layer                           │
│  - Models           │  - ApiService (Dio + Sanctum)         │
│  - Repositories     │  - FcmService (Firebase Messaging)    │
│  - Use Cases        │  - LocalDbService (Hive/SQLite)       │
│                     │  - AuthService (Firebase Auth)        │
├─────────────────────────────────────────────────────────────┤
│  Firebase (Google)  │  Laravel 12 Backend                   │
│  - Auth             │  - API REST (/api/*)                  │
│  - FCM              │  - Sanctum Tokens                     │
│  - Analytics        │  - MySQL Database                     │
└─────────────────────────────────────────────────────────────┘
```

## 4. Flujo de Autenticación

```
1. Usuario abre app
2. Pantalla de Login con Google
3. Firebase Auth retorna idToken + user info
4. App envía POST /api/auth/google-login
   Body: { id_token, fcm_token, device_info }
5. Backend:
   - Verifica id_token con Firebase Admin SDK
   - Busca/crea User en tabla users
   - Si el email está en tabla teachers → marca role='teacher'
   - Genera Sanctum token
6. Backend responde: { user, access_token, role }
7. App guarda:
   - Sanctum token (secure storage)
   - User profile (Hive)
   - Role (parent | teacher)
8. Redirección según role y estado:
   - Parent sin hijos → Onboarding / Vincular Hijos
   - Parent con hijos → Home
   - Teacher → Home (QR propio)
```

## 5. Modelos de Datos

### 5.1 Remotos (JSON API)

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String role; // 'parent' | 'teacher'
  final String? fcmToken;
  final int? teacherId;
}

class Student {
  final int id;
  final String nombre;
  final String qrCode;
  final String? grupo;
  final String? nivel;
}

class StudentAttendance {
  final int id;
  final int studentId;
  final String type; // 'entry' | 'exit'
  final DateTime recordedAt;
}
```

### 5.2 Locales (Hive)

```dart
class LocalNotification {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;
  final Map<String, dynamic>? data; // student_id, type, etc.
}

class LocalUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String accessToken;
}
```

## 6. Pantallas y Navegación

### 6.1 Navegación Principal (BottomNavigationBar)

```
┌────────────────────────────────────────────┐
│  Home (Inicio)  │  QR  │  Notis  │  Perfil │
└────────────────────────────────────────────┘
```

| Tab | Icono | Descripción |
|-----|-------|-------------|
| **Home** | `Icons.home_rounded` | Lista de hijos (padres) o info del maestro. |
| **QR** | `Icons.qr_code_rounded` | QR del maestro (maestros) o selector de hijo para ver su QR (padres). |
| **Notis** | `Icons.notifications_rounded` | Centro de notificaciones con badge de no leídas. |
| **Perfil** | `Icons.person_rounded` | Configuración, cerrar sesión, tema. |

### 6.2 Pantallas Detalladas

#### Auth Flow
- **SplashScreen** - Logo animado, verifica sesión guardada.
- **LoginScreen** - Logo, nombre de app, botón "Iniciar sesión con Google", versión de app.

#### Parent Flow
- **OnboardingScreen** (solo primera vez) - Explicación de cómo vincular hijos.
- **LinkChildScreen** - Escáner QR (cámara) + input manual de código. Muestra preview del alumno y confirma vinculación.
- **HomeScreen** - Tarjetas de hijos vinculados. Cada tarjeta muestra: foto placeholder, nombre, grupo, nivel, último registro (entrada/salida + hora).
- **ChildDetailScreen** - Historial completo de asistencia del hijo. Filtros: Hoy, Semana, Mes. Timeline vertical.
- **ChildQrScreen** - QR grande del hijo para mostrar en checador (solo lectura, no para escanear).

#### Teacher Flow
- **HomeScreen** - Info del maestro, próximo horario, último registro de asistencia.
- **TeacherQrScreen** - QR grande del maestro para mostrar en checador.
- **AttendanceHistoryScreen** - Historial de entradas/salidas del maestro.

#### Shared Flow
- **NotificationsScreen** - Lista de notificaciones recibidas. Pull-to-refresh. Badge en tab. Soporte offline (lee de Hive).
- **ProfileScreen** - Nombre, email, foto de Google, toggle tema (claro/oscuro/sistema), versión, cerrar sesión.

## 7. Paleta de Colores (Identidad IJL)

Basada en el logo institucional (azul marino y dorado):

```dart
class IjlColors {
  static const Color primary = Color(0xFF1B3A6B);      // Azul marino
  static const Color primaryDark = Color(0xFF12284D);  // Azul marino oscuro
  static const Color accent = Color(0xFFC9A96E);       // Dorado/beige
  static const Color accentLight = Color(0xFFE8D5A3);  // Dorado claro
  static const Color background = Color(0xFFF8F9FA);   // Gris muy claro
  static const Color surface = Color(0xFFFFFFFF);      // Blanco
  static const Color textPrimary = Color(0xFF1F2937);  // Gris oscuro
  static const Color textSecondary = Color(0xFF6B7280);// Gris medio
  static const Color success = Color(0xFF10B981);      // Verde entrada
  static const Color error = Color(0xFFEF4444);        // Rojo salida/alerta
}
```

### Modo Oscuro
```dart
class IjlDarkColors {
  static const Color background = Color(0xFF0F172A);   // Slate 900
  static const Color surface = Color(0xFF1E293B);      // Slate 800
  static const Color textPrimary = Color(0xFFF1F5F9);  // Slate 100
}
```

## 8. Tipografía

```dart
class IjlTypography {
  static const String fontFamily = 'Inter'; // o Poppins
  
  static TextStyle get headlineLarge => TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: IjlColors.textPrimary);
  static TextStyle get headlineMedium => TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: IjlColors.textPrimary);
  static TextStyle get titleLarge => TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: IjlColors.textPrimary);
  static TextStyle get bodyLarge => TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: IjlColors.textPrimary);
  static TextStyle get bodyMedium => TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: IjlColors.textSecondary);
  static TextStyle get labelLarge => TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: IjlColors.primary);
}
```

## 9. Componentes Reutilizables

### 9.1 `IjlCard`
Tarjeta con sombra suave, bordes redondeados (`BorderRadius.circular(16)`), padding 16.

### 9.2 `IjlButton`
- **Primary:** Fondo `primary`, texto blanco, bordes redondeados 12.
- **Secondary:** Fondo `accent`, texto `primaryDark`.
- **Outline:** Borde 1px `primary`, fondo transparente, texto `primary`.

### 9.3 `IjlTextField`
Borde redondeado 12, borde `Color(0xFFE5E7EB)`, foco `primary`, label `textSecondary`.

### 9.4 `IjlAvatar`
Placeholder con iniciales del nombre sobre fondo `primary` con opacidad 0.1, texto `primary`.

### 9.5 `IjlBadge`
Circulo rojo pequeño para notificaciones no leídas. También badge de estado: verde (entrada), rojo (salida).

### 9.6 `IjlEmptyState`
Ilustración + título + subtítulo + botón de acción (para estados vacíos).

### 9.7 `IjlTimelineItem`
Item de timeline para historial de asistencia. Línea vertical con puntos, hora, tipo (entrada/salida), icono correspondiente.

## 10. Notificaciones Push (FCM)

### 10.1 Payload esperado del backend

```json
{
  "message": {
    "token": "<fcm_token>",
    "notification": {
      "title": "Juan Pérez - Entrada registrada",
      "body": "Tu hijo registró su entrada a las 07:45 AM"
    },
    "data": {
      "student_id": "123",
      "student_name": "Juan Pérez",
      "type": "entry",
      "recorded_at": "2026-05-27T07:45:00",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    }
  }
}
```

### 10.2 Comportamiento en App

| Estado de App | Comportamiento |
|---------------|----------------|
| **Foreground** | Muestra banner local con Snackbar/Dialog personalizado. Guarda en Hive. Actualiza badge. |
| **Background** | FCM muestra notificación del sistema. Al tocar, abre app y navega a detalle del alumno. |
| **Terminated** | FCM muestra notificación del sistema. Al tocar, abre app en Home y marca notificación como no leída. |

### 10.3 Flujo completo de notificación

```
1. Alumno escanea QR en checador (tablet de escuela)
2. Backend crea registro en student_attendances
3. Observer StudentAttendanceObserver detecta creación
4. Backend busca users vinculados en student_user para ese student_id
5. Backend envía FCM push a cada user->fcm_token
6. App recibe push, guarda en Hive, muestra banner/badge
7. User toca notificación → navega a ChildDetailScreen del alumno
```

## 11. Dependencias de Flutter (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Estado y navegación
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  
  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  firebase_messaging: ^15.0.0
  google_sign_in: ^6.2.0
  
  # HTTP y API
  dio: ^5.4.0
  retrofit: ^4.1.0
  
  # Almacenamiento local
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_secure_storage: ^9.2.0
  
  # QR
  mobile_scanner: ^5.0.0
  qr_flutter: ^4.1.0
  
  # UI
  google_fonts: ^6.2.0
  flutter_svg: ^2.0.10
  shimmer: ^3.0.0
  intl: ^0.19.0
  
  # Utilidades
  freezed_annotation: ^2.4.0
  json_annotation: ^4.9.0
  package_info_plus: ^8.0.0
  url_launcher: ^6.3.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.5.0
  json_serializable: ^6.8.0
  retrofit_generator: ^8.1.0
  hive_generator: ^2.0.1
```

## 12. Estructura de Carpetas

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── router.dart              # GoRouter configuration
│   ├── theme.dart               # ThemeData light/dark
│   └── constants.dart           # URLs, keys, timeouts
├── core/
│   ├── errors/
│   ├── extensions/
│   └── utils/
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── student_model.dart
│   │   ├── attendance_model.dart
│   │   └── notification_model.dart
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── api_service.dart   # Dio + Retrofit
│   │   └── local/
│   │       ├── hive_service.dart
│   │       └── secure_storage.dart
│   └── repositories/
│       ├── auth_repository.dart
│       ├── student_repository.dart
│       └── notification_repository.dart
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── student_provider.dart
│   │   └── notification_provider.dart
│   ├── screens/
│   │   ├── splash/
│   │   ├── auth/
│   │   │   └── login_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── children/
│   │   │   ├── link_child_screen.dart
│   │   │   ├── child_detail_screen.dart
│   │   │   └── child_qr_screen.dart
│   │   ├── teacher/
│   │   │   ├── teacher_home_screen.dart
│   │   │   └── teacher_qr_screen.dart
│   │   ├── notifications/
│   │   │   └── notifications_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── widgets/
│   │   ├── ijl_card.dart
│   │   ├── ijl_button.dart
│   │   ├── ijl_text_field.dart
│   │   ├── ijl_avatar.dart
│   │   ├── ijl_badge.dart
│   │   ├── ijl_empty_state.dart
│   │   └── ijl_timeline_item.dart
│   └── components/
├── services/
│   ├── firebase_messaging_service.dart
│   └── firebase_auth_service.dart
└── generated/
    └── assets.dart
```

## 13. Endpoints API del Backend

| Método | Endpoint | Auth | Descripción |
|--------|----------|------|-------------|
| POST | `/api/auth/google-login` | No | Login con Google. Body: `{id_token, fcm_token}` |
| GET | `/api/user` | Bearer | Obtener usuario autenticado con hijos vinculados |
| POST | `/api/vincular-alumno` | Bearer | Vincular hijo por qr_code. Body: `{codigo_alumno}` |
| POST | `/api/desvincular-alumno` | Bearer | Desvincular hijo. Body: `{student_id}` |
| GET | `/api/students` | Bearer | Lista de todos los estudiantes (para búsqueda) |
| GET | `/api/students/{id}` | Bearer | Detalle de un estudiante |
| GET | `/api/students/{id}/attendances` | Bearer | Historial de asistencia de un alumno |
| GET | `/api/teachers` | Bearer | Lista de maestros |
| POST | `/api/update-fcm-token` | Bearer | Actualizar token FCM |
| POST | `/api/logout` | Bearer | Revocar token Sanctum |

## 14. Cambios Requeridos en Backend (PR)

1. **Nuevo endpoint:** `POST /api/auth/google-login`
   - Verifica `id_token` con Firebase Admin SDK
   - Busca/crea `User` por email
   - Si email está en `teachers` → set `role='teacher'`, `teacher_id`
   - Genera Sanctum token

2. **Modificar `StudentAttendanceObserver`:**
   - Además de enviar WhatsApp a `guardians`, enviar FCM push a `users` vinculados vía `student_user` para ese `student_id`.
   - Usar `FcmNotificationService::sendToDevice()` o crear batch `sendToUsers()`.

3. **Nuevo endpoint:** `POST /api/desvincular-alumno`
   - Recibe `student_id`, remueve relación de `student_user`.

4. **Nuevo endpoint:** `GET /api/students/{id}/attendances`
   - Retorna historial de `student_attendances` paginado para un alumno específico.

## 15. Seguridad

- Sanctum token guardado en `flutter_secure_storage` (Keychain/Keystore).
- Refresh automático de token si el backend responde 401.
- Validación de `id_token` de Google en backend con Firebase Admin SDK.
- FCM token rotado y actualizado en backend en cada login y cuando Firebase lo refresca.
- Todas las llamadas a API usan HTTPS.

## 16. Rendimiento y Offline

- **Cache de imágenes:** `cached_network_image` para fotos de perfil de Google.
- **Cache de datos:** Hive guarda lista de hijos, historial reciente, y notificaciones.
- **Sincronización:** Al abrir app, refresca datos del servidor y actualiza cache local.
- **Indicadores de carga:** Shimmer en listas mientras carga.
- **Retry:** Dio con interceptor de retry (3 intentos) para operaciones críticas.

## 17. Accesibilidad

- Textos con `semanticsLabel` para lectores de pantalla.
- Contraste mínimo 4.5:1 en todos los textos.
- Botones con área táctil mínimo 48x48dp.
- Soporte para escalado de fuente del sistema.
