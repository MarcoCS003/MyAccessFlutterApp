import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cliente_flutter_myaccess/main.dart';

void main() {
  testWidgets('App login screen smoke test', (WidgetTester tester) async {
    // Build our app under ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the login screen is displayed and shows school branding and welcome messages.
    expect(find.text('Instituto Juárez Lincoln'), findsOneWidget);
    expect(find.text('Control de Acceso Escolar'), findsOneWidget);
    expect(find.text('Bienvenido'), findsOneWidget);
    expect(find.text('Inicia sesión para recibir notificaciones de acceso.'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
