import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/features/inventory/screens/stock_adjustment_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StockAdjustmentScreen(productId: '11111111-1111-1111-1111-111111111111'),
      ),
    );

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('StockAdjustmentScreen', () {
    testWidgets('renders quantity and reason fields', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Adjust stock'), findsOneWidget);
      expect(find.text('Quantity change'), findsOneWidget);
      expect(find.text('Reason'), findsOneWidget);
    });

    testWidgets('rejects an empty or non-numeric quantity', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await _tapSave(tester);
      // Quantity and reason are both empty → at least two messages.
      expect(find.text('This field is required'), findsWidgets);

      await tester.enterText(find.byType(TextFormField).at(0), 'abc');
      await _tapSave(tester);
      expect(find.text('Enter a valid number'), findsOneWidget);
    });

    testWidgets('rejects a zero adjustment', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '0');
      await _tapSave(tester);
      expect(find.text('Enter a valid number'), findsOneWidget);
    });
  });
}
