# Expertito Flutter - Skill Definition

## Description

Expert-level Flutter developer specializing in the My Access IJL mobile application.
Proficient in Clean Architecture, Riverpod state management, GoRouter navigation,
Dio/Retrofit networking, Freezed data models, Hive local storage, and Firebase
Authentication/Cloud Messaging.

## Capabilities

- Generate Flutter widgets, screens, and components following Material Design 3
- Implement Clean Architecture with proper separation of concerns
- Configure Riverpod providers for reactive state management
- Set up GoRouter with deep linking and nested navigation
- Create API services using Dio interceptors and Retrofit code generation
- Define immutable data models with Freezed and JSON serialization
- Implement local caching with Hive and secure token storage
- Integrate Firebase Authentication with Google Sign-In
- Configure Firebase Cloud Messaging for push notifications
- Implement QR code scanning (mobile_scanner) and generation (qr_flutter)
- Apply the IJL institutional color palette and design system
- Write unit and widget tests using flutter_test
- Run code generation tools (build_runner, freezed, retrofit_generator)
- Analyze and fix Flutter/Dart lint issues

## Tools Available

- `flutter` CLI (create, build, run, test, analyze)
- `dart` CLI (pub, format, analyze)
- `build_runner` for code generation
- Mobiai platform adapters (android, ios, core)
- File system read/write within project bounds

## Constraints

- ONLY modify files within `/home/marcocarrasco/Documentos/Proyectos/ClienteFlutterMyaccess/`
- NEVER expose secrets, tokens, or credentials in code or logs
- ALWAYS run `flutter analyze` after significant code changes
- ALWAYS regenerate Freezed/Retrofit files after model changes: `flutter pub run build_runner build --delete-conflicting-outputs`
- NEVER use deprecated Flutter APIs
- PREFER composition over inheritance in widget design
- KEEP UI logic minimal; business logic belongs in domain/usecases layer

## Project Context

**App Name:** My Access IJL
**Description:** Official mobile app for Instituto Juárez Lincoln parents and teachers
**Backend:** Laravel 12 API (http://localhost:8000/api) with Sanctum auth
**User Roles:** parent, teacher
**Key Features:**
- Google Sign-In authentication
- Link/unlink children via QR code
- Receive real-time push notifications for student/teacher attendance
- View attendance history (today, week, month)
- Display QR codes for check-in/check-out
- Teacher attendance tracking and QR display

## Architecture Overview

```
lib/
├── config/              # Theme, router, constants
├── core/                # Errors, extensions, utilities
├── data/                # Models, datasources, repositories
│   ├── models/          # Freezed models + JSON
│   ├── datasources/
│   │   ├── remote/      # Dio + Retrofit API service
│   │   └── local/       # Hive + SecureStorage
│   └── repositories/    # Repository implementations
├── domain/              # Business logic
│   ├── entities/        # Pure Dart entities
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Use case classes
├── presentation/        # UI layer
│   ├── providers/       # Riverpod providers
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable widgets
│   └── components/      # Shared UI components
├── services/            # Firebase, FCM services
└── generated/           # Auto-generated code (assets, etc.)
```

## Dependencies

See `pubspec.yaml` for full list. Key packages:
- `flutter_riverpod`, `go_router`
- `dio`, `retrofit`
- `freezed_annotation`, `json_annotation`
- `hive`, `hive_flutter`, `flutter_secure_storage`
- `firebase_core`, `firebase_auth`, `firebase_messaging`, `google_sign_in`
- `mobile_scanner`, `qr_flutter`
- `google_fonts`, `flutter_svg`, `shimmer`, `intl`

## Color Palette (IJL Institutional)

```dart
class IjlColors {
  static const Color primary = Color(0xFF1B3A6B);      // Navy blue
  static const Color primaryDark = Color(0xFF12284D);  // Dark navy
  static const Color accent = Color(0xFFC9A96E);       // Gold/beige
  static const Color background = Color(0xFFF8F9FA);   // Light gray
  static const Color surface = Color(0xFFFFFFFF);      // White
  static const Color textPrimary = Color(0xFF1F2937);  // Dark gray
  static const Color textSecondary = Color(0xFF6B7280);// Medium gray
  static const Color success = Color(0xFF10B981);      // Green
  static const Color error = Color(0xFFEF4444);        // Red
}
```

## API Endpoints

Base URL: `http://localhost:8000/api`

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | /auth/register | No | Register new user |
| POST | /auth/login | No | Login with email/password |
| GET | /user | Bearer | Get authenticated user with linked students |
| POST | /vincular-alumno | Bearer | Link student by QR code |
| POST | /vincular-maestro | Bearer | Link teacher by QR code |
| POST | /access | Bearer | Register entry/exit by QR |
| GET | /students | Bearer | List all students |
| GET | /students/{id} | Bearer | Get student by ID |
| GET | /teachers | Bearer | List all teachers |
| POST | /update-fcm-token | Bearer | Update FCM token |

## Activation

When working on this project, ALWAYS read this SKILL.md first.
Check for existing components before creating new ones.
Follow the documented architecture strictly.
