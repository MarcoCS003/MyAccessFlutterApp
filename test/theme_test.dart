import 'package:flutter_test/flutter_test.dart';
import 'package:cliente_flutter_myaccess/core/theme/theme.dart';

void main() {
  group('AppTheme Integration Tests', () {
    testWidgets('lightTheme is configured with correct colors', (
      WidgetTester tester,
    ) async {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppTheme.primaryColor);
      expect(theme.colorScheme.secondary, AppTheme.secondaryColor);
      expect(theme.colorScheme.tertiary, AppTheme.accentColor);
      expect(theme.scaffoldBackgroundColor, AppTheme.backgroundColor);
    });

    testWidgets('lightTheme has correct appBar styling', (
      WidgetTester tester,
    ) async {
      final theme = AppTheme.lightTheme;
      expect(theme.appBarTheme.backgroundColor, AppTheme.primaryColor);
      expect(theme.appBarTheme.centerTitle, isTrue);
      expect(theme.appBarTheme.titleTextStyle?.fontSize, 20);
    });
  });
}
