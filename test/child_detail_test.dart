import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/child_detail_screen.dart';

void main() {
  testWidgets('ChildDetailScreen renderiza cabecera', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChildDetailScreen(childId: '1'),
        ),
      ),
    );
    expect(find.text('Hoy'), findsOneWidget);
  });
}
