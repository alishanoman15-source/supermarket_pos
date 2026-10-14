import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/models/reports.dart';

void main() {
  group('SalesReportData.fromMap', () {
    test('parses grouped rows and totals from the RPC payload', () {
      final data = SalesReportData.fromMap({
        'group_by': 'day',
        'rows': [
          {
            'bucket': '2026-10-05T00:00:00Z',
            'transactions': 3,
            'gross_sales': '1500.00',
            'discounts': '50.00',
            'net_sales': '1450.00',
            'tax_collected': '100.00',
            'revenue': '1550.00',
            'avg_basket': '516.67',
          },
        ],
        'totals': {
          'transactions': 3,
          'gross_sales': 1500,
          'discounts': 50,
          'net_sales': 1450,
          'tax_collected': 100,
          'revenue': 1550,
          'items_per_txn': 2.5,
        },
      });

      expect(data.groupBy, 'day');
      expect(data.rows, hasLength(1));
      expect(data.rows.first.transactions, 3);
      expect(data.rows.first.revenue, Decimal.parse('1550.00'));
      expect(data.revenue, Decimal.parse('1550'));
      expect(data.itemsPerTxn, Decimal.parse('2.5'));
    });

    test('handles an empty result set', () {
      final data = SalesReportData.fromMap({'group_by': 'day', 'rows': [], 'totals': {}});
      expect(data.rows, isEmpty);
      expect(data.revenue, Decimal.zero);
    });
  });

  group('ProfitReportData.fromMap', () {
    test('computes all money fields as Decimal', () {
      final data = ProfitReportData.fromMap({
        'revenue': '1000.00',
        'tax_collected': '50.00',
        'cogs': '600.00',
        'gross_profit': '400.00',
        'refunds': '25.00',
        'expenses': '100.00',
        'operating_profit': '275.00',
      });
      expect(data.grossProfit, Decimal.parse('400.00'));
      expect(data.operatingProfit, Decimal.parse('275.00'));
    });
  });

  group('PurchasesReportData.fromMap', () {
    test('parses suppliers, unpaid bills and ageing buckets', () {
      final data = PurchasesReportData.fromMap({
        'total_purchases': '9000.00',
        'by_supplier': [
          {'supplier_id': 's1', 'name': 'Acme', 'bills': 2, 'total': '9000.00'},
        ],
        'unpaid_bills': [
          {
            'id': 'b1',
            'bill_number': 'B-1',
            'supplier_name': 'Acme',
            'total': '5000.00',
            'paid_total': '2000.00',
            'balance': '3000.00',
            'due_at': '2026-10-30',
          },
        ],
        'supplier_ageing': [
          {
            'supplier_id': 's1',
            'name': 'Acme',
            'bucket_0_30': '3000.00',
            'bucket_30_60': '0',
            'bucket_60_90': '0',
            'bucket_90_plus': '0',
          },
        ],
      });

      expect(data.totalPurchases, Decimal.parse('9000.00'));
      expect(data.bySupplier.single.name, 'Acme');
      expect(data.unpaidBills.single.balance, Decimal.parse('3000.00'));
      expect(data.supplierAgeing.single.b0To30, Decimal.parse('3000.00'));
    });
  });

  group('InventoryReportData.fromMap', () {
    test('parses valuation and expiring batches', () {
      final data = InventoryReportData.fromMap({
        'value_at_cost': '12000.00',
        'value_at_retail': '18000.00',
        'margin_value': '6000.00',
        'low_stock_count': 4,
        'out_of_stock_count': 1,
        'dead_stock': [
          {'product_id': 'p1', 'name': 'Rice', 'on_hand': '10', 'wac': '200.00', 'last_sold_at': null},
        ],
        'expiring': [
          {
            'batch_id': 'bt1',
            'product_id': 'p2',
            'name': 'Milk',
            'batch_no': 'B-1',
            'expiry_date': '2026-10-25',
            'qty': '12',
          },
        ],
      });

      expect(data.valueAtRetail, Decimal.parse('18000.00'));
      expect(data.marginValue, Decimal.parse('6000.00'));
      expect(data.deadStock.single.name, 'Rice');
      expect(data.expiring.single.batchNo, 'B-1');
    });
  });
}
