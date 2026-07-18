class ApiConfig {
  // ─────────────────────────────────────────────────────────────
  // URLs del backend Laravel (myAccessIJL)
  // ─────────────────────────────────────────────────────────────
  // Esta es la ÚNICA fuente de verdad para la URL del backend.
  // Para alternar entre emulador y dispositivo físico, comenta
  // y descomenta la línea correspondiente. NO modifiques el
  // backend (Laravel) para cambiar el host o puerto.

  // Backend remoto vía Tailscale (funciona desde cualquier red):
  static const String baseUrl = 'https://fedora.tail6fabd9.ts.net:8443/api';

  // Dispositivo físico en la red 192.168.17.x: IP local de la
  // máquina donde corre `php artisan serve`. Según el entorno el
  // backend escucha en 8000 o 8001; alterna comentando la línea.
  // static const String baseUrl = 'http://192.168.17.135:8001/api';
  // static const String baseUrl = 'http://192.168.17.135:8000/api';

  // Android Emulator: usa localhost + `adb reverse tcp:8000 tcp:8000`
  // (mapea el localhost del emulador al localhost del host, donde
  // escucha el backend). Funciona aunque el emulador no tenga Wi-Fi.
  // static const String baseUrl = 'http://localhost:8000/api';
}
