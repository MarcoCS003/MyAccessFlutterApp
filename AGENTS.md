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
- **Change the backend URL only via `lib/core/constants/api_config.dart`.** This is the single source of truth for the API base URL. `ApiConfig.baseUrl` reads `String.fromEnvironment('API_BASE_URL')` with the **production URL `https://checador.ijl.com.mx/api` as default**, so release builds always point to the official backend. For local development, override with `--dart-define` (do NOT edit the file), e.g.:
  - Tailscale (any network): `flutter run --dart-define=API_BASE_URL=https://marcoijl.tail6fabd9.ts.net/api`
  - Physical device on LAN: `flutter run --dart-define=API_BASE_URL=http://192.168.100.4:8000/api`
  - Android emulator: `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api` (plus `adb reverse tcp:8000 tcp:8000`)
- **Auth is currently mocked.** `lib/features/auth/providers/auth_provider.dart` uses a hardcoded `MockUser` and manual `login()` / `logout()` / `toggleRole()`.
- **Firebase is configured** for project `notificacionesapptutores`:
  - Android: `android/app/google-services.json` (package `com.jmoreno.riverboldbrave`).
  - iOS: `ios/Runner/GoogleService-Info.plist` (bundle `com.ijl.clienteFlutterMyaccess`).
  - Dart options: `lib/firebase_options.dart`.
- **Crashlytics is integrated** (`firebase_crashlytics`, Fase 8.2):
  - Global capture in `main.dart`: `FlutterError.onError`, `PlatformDispatcher.onError`, and `runZonedGuarded` wrapping ALL of the async init (order matters: Firebase → Crashlytics handlers → zone). The FCM background handler has its own try/catch that reports via `recordError`.
  - `ErrorWidget.builder` → `appErrorBuilder` in `lib/core/widgets/app_error_widget.dart` (friendly IJL-palette screen instead of the red one; red screen still shows in debug builds).
  - ALL Crashlytics calls go through `lib/core/utils/crash_report.dart` (`crashLog` / `crashRecordError` / `crashSetUser` / `crashSetRole`) — best-effort wrappers that swallow errors so tests (no Firebase init) and the app never break. Use them, never `FirebaseCrashlytics.instance` directly, outside `main.dart`.
  - **No PII ever** in breadcrumbs/keys: only `user_<id>`, `role`, FCM `data['type']`, `METHOD path` (no query/headers/body). User identity is set in `AuthNotifier` on login/restore/switch and cleared on logout.
  - Hive hardening: catch blocks in `notification_local_store.dart` and `children_provider.dart` report and delete ONLY the affected `items_<userKey>` key — never `box.clear()`.
- **No API service layer exists yet.** `lib/services/` only has `api_service.dart` (Dio) and `local_notifications_service.dart`; `lib/data/datasources/remote/` and `lib/data/models/` are empty.

## FCM Notifications (source of truth is local)

- **Local data is namespaced per account** (`items_<userKey>`, userKey = normalized email, see `lib/core/utils/user_key.dart`): notifications in `notifications_box` and the children cache in `children_box`. `notificationProvider`/`childrenProvider` watch the authenticated user's email and are recreated on login/logout, so one account never sees another's data on the same device. The old global `'items'` keys are orphaned (dev app, no migration).
- **Multi-session routing by `user_id`**: the backend includes `user_id` (recipient) in the FCM `data` payload; `resolveUserKeyForNotification` (`lib/core/utils/user_key.dart`) matches it against `user.id` of the saved sessions (`auth_box['sessions']`, see `SessionStore`). If the recipient has no session on the device, the message is **discarded** (not saved, no tray, no ACK). Payloads without `user_id` fall back to legacy content-based routing (role / children cache / anonymous inbox `items__anonymous`).
- **Every persisted FCM message goes to Hive** (`notifications_box`) through `lib/features/notifications/data/notification_local_store.dart`, with dedupe by `NotificationItem.id` (`studentId_event_timestamp`, built from the raw payload strings).
- **ACKs are per account**: `main.dart` ACKs with the JWT of the notification's owner (`SessionStore.getJwt(ownerKey)` + `ApiService(authToken:)`), not the active session's JWT.
- **Multi-session background sync**: `notification_sync_task.dart` iterates ALL saved sessions, each with its own JWT (`GET /notifications/sync` returns the JWT owner's pending items), so every inbox stays fresh even when its account isn't active. Items whose `user_id` doesn't match the synced account are discarded without ACK.
- **Real backend payload** (confirmed in device logs 2026-08-23; history in `docs/reporte_notificaciones_fcm.md`): `data` carries `{type: attendance, user_id, student_id|teacher_id, event: entry|exit, recorded_at, person_name, notification_id}` (the non-applicable id key comes as an empty string). `NotificationItem.fromFcm` accepts aliases (`attendance_type`, `recorded_at`, `event_type`, `tipo`, `nombre`, ...) and normalizes the event to `check_in`/`check_out`, which is what the UI expects.
- **Backend messages include a `notification` key**, so in background/terminated state Android shows the system tray itself and `onBackgroundMessage` does NOT fire — nothing is persisted unless the user taps (`onMessageOpenedApp`). Persisting in background requires the backend to send data-only messages (backend change, applied by the user; never touch the backend project).
- **The FCM background handler and the sync task run in a SEPARATE isolate** with their own Hive instance: their writes hit the disk but the foreground isolate's open box does NOT see them. `notificationProvider.reloadFromLocal()` closes and reopens `notifications_box` to re-read from disk; it runs on `AppLifecycleState.resumed` in `main.dart`. The notifier constructor still loads synchronously (the box was just opened in `main()`).
- **`notificationProvider` feeds the UI**: notifications screen, `childrenWithActivityProvider` (single provider for ChildCard/status in `home_padre_screen` and `child_detail_screen`) and `childTimelineProvider` (detail history/stats). Child status/timeline come from the local DB, NOT from new backend calls.
- **System tray notifications** are shown via `flutter_local_notifications` (`lib/services/local_notifications_service.dart`, channel `attendance_channel`) for foreground and background data-only messages.
- `main.dart` reloads the provider from Hive (reopening the box, see the isolate note above) on `AppLifecycleState.resumed`, and persists tapped tray notifications via `onMessageOpenedApp`/`getInitialMessage`.
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
