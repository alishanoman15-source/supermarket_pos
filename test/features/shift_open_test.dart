import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/features/shifts/screens/shift_open_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShiftOpenScreen(),
      ),
    );

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('ShiftOpenScreen', () {
    testWidgets('renders the opening float field', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Open shift'), findsOneWidget);
      expect(find.text('Opening float'), findsOneWidget);
    });

    testWidgets('rejects a non-numeric or negative float', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '-5');
      await _tapSave(tester);
      expect(find.text('Enter a valid number'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'abc');
      await _tapSave(tester);
      expect(find.text('Enter a valid number'), findsOneWidget);
    });
  });
}
