import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cliente_flutter_myaccess/features/padres/models/child.dart';
import 'package:cliente_flutter_myaccess/features/padres/providers/children_provider.dart';

class MockChildrenNotifier extends ChildrenNotifier {
  MockChildrenNotifier(List<Child> children) : super() {
    state = AsyncValue.data(children);
  }
}
