import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Builder global para `ErrorWidget.builder`: reporta el error a
/// Crashlytics (best-effort) y muestra [AppErrorWidget] en lugar de la
/// pantalla roja. Conectar en `main()` antes de `runApp`.
Widget appErrorBuilder(FlutterErrorDetails details) {
  try {
    FirebaseCrashlytics.instance.recordFlutterError(details);
  } catch (_) {}
  return const AppErrorWidget();
}

/// Pantalla de error amable con la paleta IJL. Reemplaza la pantalla roja
/// de Flutter en builds de release/profile (en debug Flutter muestra la
/// roja de todas formas).
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppTheme.accentGoldColor,
            ),
            SizedBox(height: 16),
            Text('Algo salió mal. Reinicia la app.'),
            SizedBox(height: 8),
            Text(
              'El error ya fue reportado automáticamente.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
