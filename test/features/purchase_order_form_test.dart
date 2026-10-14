import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/models/supplier.dart';
import 'package:supermarket_pos/features/parties/providers/parties_providers.dart';
import 'package:supermarket_pos/features/purchasing/screens/purchase_order_form_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

Supplier _supplier(String id, String name) => Supplier(
      id: id,
      name: name,
      openingBalance: Decimal.zero,
      status: 'active',
      createdAt: DateTime(2026, 1, 1),
    );

Widget _wrap(List<Supplier> suppliers) => ProviderScope(
      overrides: [
        supplierOptionsProvider.overrideWith((ref) async => suppliers),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PurchaseOrderFormScreen(),
      ),
    );

void main() {
  group('PurchaseOrderFormScreen supplier picker', () {
    testWidgets('opens the dropdown and selects a supplier', (tester) async {
      await tester.pumpWidget(_wrap([
        _supplier('s1', 'Karim Traders'),
        _supplier('s2', 'Dawn Distributors'),
      ]));
      await tester.pumpAndSettle();

      // Field renders with the required supplier label and no selection yet.
      expect(find.text('Supplier *'), findsOneWidget);
      expect(find.text('Karim Traders'), findsNothing);

      // Opening the dropdown is the interaction that was reported broken.
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Karim Traders'), findsOneWidget);
      expect(find.text('Dawn Distributors'), findsOneWidget);

      await tester.tap(find.text('Karim Traders').last);
      await tester.pumpAndSettle();

      // The chosen value now shows in the field (menu closed).
      expect(find.text('Karim Traders'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('shows an actionable empty state when there are no suppliers',
        (tester) async {
      await tester.pumpWidget(_wrap(const []));
      await tester.pumpAndSettle();

      expect(
        find.text('No suppliers yet. Add your first supplier.'),
        findsOneWidget,
      );
      expect(find.text('Add supplier'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    });
  });
}
