class ApiConfig {
  // ─────────────────────────────────────────────────────────────
  // URLs del backend Laravel (myAccessIJL)
  // ─────────────────────────────────────────────────────────────
  // Esta es la ÚNICA fuente de verdad para la URL del backend.
  // Para alternar entre emulador y dispositivo físico, comenta
  // y descomenta la línea correspondiente. NO modifiques el
  // backend (Laravel) para cambiar el host o puerto.

  // Android Emulator: usa localhost + `adb reverse tcp:8000 tcp:8000`
  // (mapea el localhost del emulador al localhost del host, donde
  // escucha el backend). Funciona aunque el emulador no tenga Wi-Fi.
  static const String baseUrl = 'http://192.168.17.135:8000/api';

  // Dispositivo físico en la misma red Wi-Fi:
  // usa la IP local de la máquina donde corre `php artisan serve`.
  // static const String  baseUrl = 'http://localhost:8000/api';
}
