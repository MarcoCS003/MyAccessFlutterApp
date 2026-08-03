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
- **No API service layer exists yet.** `lib/services/` only has `api_service.dart` (Dio) and `local_notifications_service.dart`; `lib/data/datasources/remote/` and `lib/data/models/` are empty.

## FCM Notifications (source of truth is local)

- **Local data is namespaced per account** (`items_<userKey>`, userKey = normalized email, see `lib/core/utils/user_key.dart`): notifications in `notifications_box` and the children cache in `children_box`. `notificationProvider`/`childrenProvider` watch the authenticated user's email and are recreated on login/logout, so one account never sees another's data on the same device. FCM handlers resolve the userKey from `auth_box['user']` via `NotificationLocalStore.forCurrentUser()`; without a saved session they write to a fixed anonymous inbox (`items__anonymous`) that the UI never reads. The old global `'items'` keys are orphaned (dev app, no migration).
- **Every FCM message is persisted to Hive** (`notifications_box`) through `lib/features/notifications/data/notification_local_store.dart` — both the foreground listener and the background handler use it, with dedupe by `NotificationItem.id` (`studentId_event_timestamp`, built from the raw payload strings).
- **Real backend payload** (see `docs/reporte_notificaciones_fcm.md`): `data` carries `{type: student_attendance, student_id, attendance_type: entry|exit, recorded_at}` — NOT `event`/`timestamp`/`student_name`. `NotificationItem.fromFcm` accepts aliases (`attendance_type`, `recorded_at`, `event_type`, `tipo`, `nombre`, ...) and normalizes the event to `check_in`/`check_out`, which is what the UI expects.
- **Backend messages include a `notification` key**, so in background/terminated state Android shows the system tray itself and `onBackgroundMessage` does NOT fire — nothing is persisted unless the user taps (`onMessageOpenedApp`). Persisting in background requires the backend to send data-only messages (backend change, applied by the user; never touch the backend project).
- **`notificationProvider` feeds the UI**: notifications screen, `childrenWithActivityProvider` (single provider for ChildCard/status in `home_padre_screen` and `child_detail_screen`) and `childTimelineProvider` (detail history/stats). Child status/timeline come from the local DB, NOT from new backend calls.
- **System tray notifications** are shown via `flutter_local_notifications` (`lib/services/local_notifications_service.dart`, channel `attendance_channel`) for foreground and background data-only messages.
- `main.dart` reloads the provider from Hive on `AppLifecycleState.resumed`, and persists tapped tray notifications via `onMessageOpenedApp`/`getInitialMessage`.
- `main.dart` also calls `initializeDateFormatting('es')` at startup — required by the `DateFormat(..., 'es')` usages in the child detail timeline; without it they throw `LocaleDataException`.
- FCM `timestamp` values are parsed with `.toLocal()` in `NotificationItem.fromFcm` — backend UTC timestamps must not be compared raw against local "today".
- `recentActivityProvider` and the Home "Actividad reciente" section were removed (redundant with `child_detail_screen`).

## Theming

- Material 3 with custom IJL palette defined in `lib/core/theme/theme.dart`.
- Key colors:
  - Primary: `#002452`
  - Navy: `#1B3A6B`
  - Accent/Gold: `#745A27`
  - Light Gold: `#FEDB9B`
- Fonts: `GoogleFonts.poppins()` for headings, `GoogleFonts.inter()` for body.

## Debug Features

- A `DebugRoleToggleBtn` is permanently overlaid at bottom-left when authenticated. It toggles between `parent` and `teacher` roles to switch home screens without re-login. Do not remove unless explicitly asked.
- **Demo seed (debug only):** when `MainNavigationScreen` mounts, `_seedDemoIfNeeded()` seeds Mon–Fri entry/exit notifications for the logged-in user via `NotificationSeeder` (`lib/features/notifications/data/notification_seeder.dart`) — 30 days back for parents (each linked child), 60 days back for teachers (own attendance, to fill the home's week-grouped month view). Runs only under `kDebugMode`, once per user email (flag `demo_seed_v2_<email>` in `settingsBox`; the v2 suffix forces a one-time reseed over older installs — id-dedup absorbs overlap). `signOut` does NOT wipe local data (deliberate, to test multiple users on one device), so seeded data persists across logins, namespaced per account. Seeded items are marked with `location: 'Demo'` and `isRead: true`.

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
- **Core library desugaring is enabled** (`isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs`) — required by `flutter_local_notifications`; do not remove.
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
