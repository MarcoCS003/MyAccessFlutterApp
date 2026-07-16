import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/link_child_screen.dart';

void main() {
  testWidgets('LinkChildScreen renderiza panel de escaneo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LinkChildScreen())),
    );
    expect(find.text('Vincular Hijo'), findsOneWidget);
  });
}
