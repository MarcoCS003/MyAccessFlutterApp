import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/home_padre_screen.dart';

void main() {
  testWidgets('HomePadreScreen renderiza lista de estudiantes', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HomePadreScreen()),
        ),
      ),
    );
    expect(find.text('Tus hijos vinculados'), findsOneWidget);
  });
}
