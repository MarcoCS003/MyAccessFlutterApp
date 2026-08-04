class ApiConfig {
  // ─────────────────────────────────────────────────────────────
  // URL del backend Laravel (myAccessIJL)
  // ─────────────────────────────────────────────────────────────
  // Esta es la ÚNICA fuente de verdad para la URL del backend.
  //
  // El default es PRODUCCIÓN (https://checador.ijl.com.mx/api),
  // así los builds de release siempre apuntan al servidor oficial
  // sin riesgo de olvidar cambiar una línea.
  //
  // Para desarrollo local, sobrescribe con --dart-define:
  //
  //   # Backend remoto vía Tailscale (funciona desde cualquier red):
  //   flutter run --dart-define=API_BASE_URL=https://marcoijl.tail6fabd9.ts.net/api
  //
  //   # Dispositivo físico en la red local (php artisan serve):
  //   flutter run --dart-define=API_BASE_URL=http://192.168.100.4:8000/api
  //
  //   # Android Emulator (requiere `adb reverse tcp:8000 tcp:8000`):
  //   flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
  //
  // NO modifiques el backend (Laravel) para cambiar el host o puerto.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://checador.ijl.com.mx/api',
  );
}
