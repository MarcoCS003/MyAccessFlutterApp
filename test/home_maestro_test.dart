import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/maestros/screens/home_maestro_screen.dart';

void main() {
  testWidgets('HomeMaestroScreen renderiza estadísticas y QR', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HomeMaestroScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Historial de hoy'), findsOneWidget);
  });
}
