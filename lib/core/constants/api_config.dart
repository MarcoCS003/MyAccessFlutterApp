class ApiConfig {
  // ─────────────────────────────────────────────────────────────
  // URLs del backend Laravel (myAccessIJL)
  // ─────────────────────────────────────────────────────────────

  // Android Emulator: redirige 10.0.2.2 a la máquina host.
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Dispositivo físico en la misma red Wi-Fi:
  // usa la IP local de la máquina donde corre `php artisan serve`.
  static const String baseUrl = 'http://192.168.20.206:8000/api';
}
