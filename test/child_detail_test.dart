import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cliente_flutter_myaccess/features/padres/models/child.dart';
import 'package:cliente_flutter_myaccess/features/padres/models/timeline_event.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';
import 'package:cliente_flutter_myaccess/features/padres/screens/child_detail_screen.dart';

import 'mocks/children_mocks.dart';

void main() {
  final testChild = Child(
    id: 1,
    name: 'Juan Pérez',
    grade: '3ro Primaria',
    group: 'A',
    status: 'inside',
  );

  testWidgets('ChildDetailScreen renderiza cabecera', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          childrenProvider.overrideWith(
            (ref) => MockChildrenNotifier([testChild]),
          ),
          childTimelineProvider.overrideWith((ref, childId) async {
            return <TimelineEvent>[];
          }),
        ],
        child: const MaterialApp(home: ChildDetailScreen(childId: '1')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Juan Pérez'), findsOneWidget);
  });
}
