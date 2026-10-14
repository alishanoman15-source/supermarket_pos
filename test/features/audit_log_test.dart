import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supermarket_pos/data/models/audit_log.dart';
import 'package:supermarket_pos/features/audit/screens/audit_log_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

Widget _wrap(AuditLogEntry entry) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: AuditDetailSheet(entry: entry)),
    );

AuditLogEntry _entry({
  String action = 'user.invite',
  Map<String, dynamic>? before,
  Map<String, dynamic>? after,
}) =>
    AuditLogEntry(
      id: 'e1',
      action: action,
      createdAt: DateTime(2026, 10, 14, 13, 10),
      actorName: 'Alisha',
      tableName: 'profiles',
      beforeData: before,
      afterData: after,
    );

void main() {
  group('AuditDetailSheet', () {
    testWidgets('labels the payload After — never the price-specific labels',
        (tester) async {
      await tester.pumpWidget(_wrap(_entry(after: {
        'name': 'ali',
        'email': 'alishanomann@gmail.com',
        'role_key': 'cashier',
        'branch_id': null,
      })));

      expect(find.text('user.invite'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      // The old bug: every entry was labelled "New price".
      expect(find.text('New price'), findsNothing);
      expect(find.text('Old price'), findsNothing);

      // Keys are humanised and null values read as a dash.
      expect(find.text('Role Key'), findsOneWidget);
      expect(find.text('cashier'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Branch Id'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);

      // Context line: actor · table · time.
      expect(find.textContaining('Alisha'), findsOneWidget);
      expect(find.textContaining('profiles'), findsOneWidget);
    });

    testWidgets('shows Before and After side by side for a change', (tester) async {
      await tester.pumpWidget(_wrap(_entry(
        action: 'product.price_change',
        before: {'selling_price': '500'},
        after: {'selling_price': '550'},
      )));

      expect(find.text('Before'), findsOneWidget);
      expect(find.text('After'), findsOneWidget);
      expect(find.text('Selling Price'), findsNWidgets(2));
      expect(find.text('500'), findsOneWidget);
      expect(find.text('550'), findsOneWidget);
      expect(find.text('Old price'), findsNothing);
      expect(find.text('New price'), findsNothing);
    });

    testWidgets('renders nested payloads as indented JSON', (tester) async {
      await tester.pumpWidget(_wrap(_entry(
        action: 'stock.adjust',
        after: {'meta': {'reason': 'Damaged', 'qty': -3}},
      )));

      expect(find.text('Meta'), findsOneWidget);
      expect(find.textContaining('"reason": "Damaged"'), findsOneWidget);
      expect(find.textContaining('"qty": -3'), findsOneWidget);
    });

    testWidgets('explains when the entry stored no payload', (tester) async {
      await tester.pumpWidget(_wrap(_entry(action: 'shift.close')));

      expect(
        find.text('No stored changes for this entry.'),
        findsOneWidget,
      );
      expect(find.text('Changes'), findsNothing);
    });
  });
}
