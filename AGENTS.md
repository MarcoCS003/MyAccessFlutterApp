# AGENTS.md — Cliente Flutter MyAccess IJL

> Compact guidance for OpenCode sessions. Skip generic Flutter advice; focus on what is easy to miss.

## Project Identity

- **Name:** `cliente_flutter_myaccess` — Flutter client for *MyAccess IJL* (school access control).
- **Flutter SDK:** `^3.12.0` (stable channel, revision `559ffa3f75e7402d65a8def9c28389a9b2e6fe42`).
- **Platforms configured:** Android, iOS, Linux, macOS, Web, Windows.

## Architecture Reality Check

- **Folder structure follows Clean Architecture** (`core/`, `data/`, `domain/`, `features/`), but most data/domain layers are **currently empty stubs**.
- **State management:** Riverpod (`flutter_riverpod`). All screens are `ConsumerWidget` or wrapped in `ProviderScope`.
- **Navigation:** GoRouter (`lib/core/router/router.dart`). Never use `Navigator.push` directly.
- **Routing notes:**
  - Initial route: `/login`
  - Authenticated users redirect to `/home`
  - Routes exist for `/parent-home`, `/teacher-home`, `/link-child`, `/child/:id`, `/qr`, `/notifications`.

## Auth & Backend (Critical)

- **⚠️ NEVER MODIFY THE BACKEND.** The Laravel backend (`/home/marcocarrasco/Documentos/Proyectos/myAccessIJL`) is a separate project. Do NOT start/stop it, change its port, host binding, or configuration. It runs as `php artisan serve` (default `127.0.0.1:8000`) managed by the user. If you need the emulator to reach it, use `adb reverse tcp:8000 tcp:8000` instead.
- **Change the backend URL only via `lib/core/constants/api_config.dart`.** This is the single source of truth for the API base URL — toggle between emulator (`10.0.2.2`) and physical device (`192.168.20.206`) by commenting/uncommenting `ApiConfig.baseUrl`.
- **Auth is currently mocked.** `lib/features/auth/providers/auth_provider.dart` uses a hardcoded `MockUser` and manual `login()` / `logout()` / `toggleRole()`.
- **Firebase is configured** for project `notificacionesapptutores`:
  - Android: `android/app/google-services.json` (package `com.jmoreno.riverboldbrave`).
  - iOS: `ios/Runner/GoogleService-Info.plist` (bundle `com.ijl.clienteFlutterMyaccess`).
  - Dart options: `lib/firebase_options.dart`.
- **No API service layer exists yet.** `lib/services/`, `lib/data/datasources/remote/`, and `lib/data/models/` are empty.

## Theming

- Material 3 with custom IJL palette defined in `lib/core/theme/theme.dart`.
- Key colors:
  - Primary: `#002452`
  - Navy: `#1B3A6B`
  - Accent/Gold: `#745A27`
  - Light Gold: `#FEDB9B`
- Fonts: `GoogleFonts.poppins()` for headings, `GoogleFonts.inter()` for body.

## Debug Features in `main.dart`

- A `DebugRoleToggleBtn` is permanently overlaid at bottom-left when authenticated. It toggles between `parent` and `teacher` roles to switch home screens without re-login. Do not remove unless explicitly asked.

## Developer Commands

```bash
# Install dependencies
flutter pub get

# Run in debug mode
flutter run

# Run all tests (8 widget tests exist)
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis (uses package:flutter_lints/flutter.yaml)
flutter analyze

# Format code
dart format lib/ test/

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release
```

- **No code generation is currently required.** `build_runner` is in `dev_dependencies`, but `freezed`, `retrofit`, `json_serializable`, and `hive_generator` are commented out in `pubspec.yaml`. Do not run `dart run build_runner build` unless those packages are uncommented.

## Lint & Analysis

- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` with no custom rule overrides.
- Prefer fixing lints over adding `ignore:` comments.

## Android Build Notes

- `android/app/build.gradle.kts` uses Java/Kotlin **JVM 17**.
- Package name: `com.jmoreno.riverboldbrave` (matches the existing Firebase Android app).
- Release builds currently sign with the debug key (TODO in config).

## iOS / macOS Build Notes

- iOS bundle ID: `com.ijl.clienteFlutterMyaccess`.
- Firebase iOS config is present, but iOS builds must be run on macOS with Xcode.
- See `docs/EJECUCION_MAC.md` for the exact steps to run on the Mac.

## Testing Conventions

- Widget tests must wrap the app in `ProviderScope(child: MyApp())` because `MyApp` is a `ConsumerWidget`.
- Existing tests verify UI text (branding, buttons) rather than business logic.
- No unit tests for providers yet; mock auth state manually when needed.

## Docs & Plans

- `docs/planAppMyacces.md` — Detailed implementation plan (Spanish).
- `docs/diseño.md` — UI/UX design spec (Spanish).
- `docs/promptStich.md` — Prompt stitching doc (Spanish).
- `.mobiai/agent.yaml` — Intended architecture rules (note: some items like Freezed/Retrofit/Hive are aspirational and not yet reflected in `pubspec.yaml`).

## Monorepo / Multi-package

- Single Flutter app. No monorepo or workspace boundaries.

## CI / CD

- No GitHub Actions or other CI configured.
