import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/profile/screens/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renderiza detalles del usuario', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    expect(find.text('Configuración'), findsOneWidget);
  });
}
