import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/models/dashboard_kpis.dart';
import 'package:supermarket_pos/features/dashboard/providers/dashboard_provider.dart';
import 'package:supermarket_pos/features/dashboard/screens/dashboard_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

DashboardKpis _kpis({bool withSales = true}) => DashboardKpis(
      revenue: Decimal.parse('12345.50'),
      previousRevenue: Decimal.parse('10000.00'),
      transactions: 42,
      grossProfit: Decimal.parse('3210.25'),
      lowStockCount: 3,
      topProducts: withSales
          ? [
              TopProduct(
                name: 'Cola 1L',
                qtySold: Decimal.parse('120'),
                revenue: Decimal.parse('12000'),
              ),
              TopProduct(
                name: 'Chips',
                qtySold: Decimal.parse('80'),
                revenue: Decimal.parse('4000'),
              ),
            ]
          : const [],
      sales: SalesWindows(
        today: Decimal.parse('12345.50'),
        yesterday: Decimal.parse('9000.00'),
        week: Decimal.parse('60000.00'),
        month: Decimal.parse('250000.00'),
        total: Decimal.parse('987654.00'),
      ),
      orders: const OrderCounts(
        total: 42,
        completed: 40,
        returned: 1,
        cancelled: 1,
      ),
      inventory: InventoryHealth(
        totalProducts: 120,
        totalStockUnits: Decimal.parse('4800'),
        lowStockCount: 3,
        outOfStockCount: 1,
        expiredBatches: 0,
        expiringWithin7Days: 2,
        expiringWithin30Days: 5,
      ),
      financials: Financials(
        revenue: Decimal.parse('12345.50'),
        costOfGoods: Decimal.parse('9135.25'),
        grossProfit: Decimal.parse('3210.25'),
        expenses: Decimal.parse('1000.00'),
        netProfit: Decimal.parse('2210.25'),
      ),
      salesByDay: [
        SeriesPoint(
          date: DateTime(2026, 10, 1),
          transactions: 3,
          revenue: Decimal.parse('900'),
        ),
        SeriesPoint(
          date: DateTime(2026, 10, 2),
          transactions: 2,
          revenue: Decimal.parse('1200'),
        ),
      ],
      salesByMonth: [
        SeriesPoint(
          date: DateTime(2026, 9, 1),
          transactions: 20,
          revenue: Decimal.parse('25000'),
        ),
      ],
      salesByCategory: [
        CategorySlice(
          category: 'Beverages',
          qtySold: Decimal.parse('10'),
          revenue: Decimal.parse('1000'),
        ),
      ],
      paymentMethods: [
        PaymentSlice(method: 'cash', amount: Decimal.parse('900'), payments: 2),
      ],
    );

Widget _wrap(DashboardKpis kpis) => ProviderScope(
      overrides: [
        dashboardKpisProvider.overrideWith((ref) async => kpis),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(),
      ),
    );

/// Drags the dashboard's [ListView] until [target] is on screen (the list is
/// lazy, so sections below the fold are not built yet).
Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  final list = find.byType(ListView);
  for (var i = 0; i < 40 && target.evaluate().isEmpty; i++) {
    await tester.drag(list.first, const Offset(0, -400));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('DashboardScreen', () {
    testWidgets('renders KPI tiles and the ranked top-products list',
        (tester) async {
      await tester.pumpWidget(_wrap(_kpis()));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Revenue today'), findsOneWidget);
      expect(find.text('Transactions today'), findsOneWidget);
      // Revenue rose from 10,000 to 12,345.50 (+23.5%).
      expect(find.textContaining('23.5'), findsOneWidget);

      // Product spec §7 blocks — each sits further down the scroll view.
      for (final label in [
        'Total sales',
        'Total invoices',
        'Net profit',
        'Stock units',
        'Sales by day',
        'Payment methods',
        'Top products',
      ]) {
        await _scrollTo(tester, find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
      }

      expect(find.text('Cola 1L'), findsOneWidget);
      expect(find.text('Chips'), findsOneWidget);
    });

    testWidgets('shows the empty state when nothing has sold', (tester) async {
      await tester.pumpWidget(_wrap(_kpis(withSales: false)));
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('No sales yet for this period.'));
      await tester.pumpAndSettle();
      expect(find.text('No sales yet for this period.'), findsOneWidget);
    });
  });
}
