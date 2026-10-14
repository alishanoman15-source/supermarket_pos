import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/models/expense.dart';
import 'package:supermarket_pos/data/models/product_batch.dart';
import 'package:supermarket_pos/data/models/promotion.dart';
import 'package:supermarket_pos/data/models/purchase.dart';

void main() {
  group('Purchase', () {
    test('balance = total - paid_total', () {
      final purchase = Purchase.fromMap({
        'id': 'p1',
        'supplier_id': 's1',
        'supplier_name': 'Acme',
        'status': 'partially_paid',
        'subtotal': '1000.00',
        'tax_total': '100.00',
        'total': '1100.00',
        'paid_total': '400.00',
        'received_at': '2026-10-01T10:00:00Z',
      });
      expect(purchase.balance, Decimal.parse('700.00'));
      expect(purchase.total, Decimal.parse('1100.00'));
    });
  });

  group('PurchaseOrder', () {
    test('receivable only once approved or partially received', () {
      PurchaseOrder parse(String status) => PurchaseOrder.fromMap({
            'id': 'po1',
            'branch_id': 'b1',
            'supplier_id': 's1',
            'supplier_name': 'Acme',
            'status': status,
            'subtotal': '0',
            'tax_total': '0',
            'total': '0',
            'created_at': '2026-10-01T10:00:00Z',
          });

      expect(parse('draft').isDraft, isTrue);
      expect(parse('draft').canReceive, isFalse);
      expect(parse('approved').canReceive, isTrue);
      expect(parse('partially_received').canReceive, isTrue);
      expect(parse('received').canReceive, isFalse);
    });
  });

  group('PurchaseOrderItem', () {
    test('progress clamps between 0 and 1', () {
      PurchaseOrderItem item(String qty, String received) => PurchaseOrderItem.fromMap({
            'id': 'i1',
            'product_id': 'p1',
            'product_name': 'Rice',
            'qty': qty,
            'received_qty': received,
            'unit_cost': '10',
            'tax_rate': '0',
            'line_total': '0',
          });
      expect(item('10', '5').progress, closeTo(0.5, 0.001));
      expect(item('10', '0').progress, 0);
      expect(item('0', '3').progress, 0);
    });
  });

  group('Promotion', () {
    test('isLive respects the active window', () {
      final now = DateTime.now();
      final promo = Promotion.fromMap({
        'id': 'pr1',
        'name': 'Weekend',
        'promo_type': 'percent_off',
        'value': '10',
        'min_qty': '0',
        'free_qty': '0',
        'is_stackable': false,
        'status': 'active',
        'starts_at': now.subtract(const Duration(days: 1)).toIso8601String(),
        'ends_at': now.add(const Duration(days: 1)).toIso8601String(),
      });
      expect(promo.isLive, isTrue);
    });

    test('isLive is false outside the window', () {
      final now = DateTime.now();
      final promo = Promotion.fromMap({
        'id': 'pr2',
        'name': 'Old',
        'promo_type': 'fixed_off',
        'value': '50',
        'min_qty': '0',
        'free_qty': '0',
        'is_stackable': false,
        'status': 'active',
        'ends_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      });
      expect(promo.isLive, isFalse);
    });
  });

  group('Expense', () {
    test('maps category name and money fields', () {
      final expense = Expense.fromMap({
        'id': 'e1',
        'branch_id': 'b1',
        'category_id': 'c1',
        'category_name': 'Rent',
        'amount': '25000.00',
        'paid_at': '2026-10-01T09:00:00Z',
        'payment_method': 'bank_transfer',
        'status': 'active',
      });
      expect(expense.categoryName, 'Rent');
      expect(expense.amount, Decimal.parse('25000.00'));
      expect(expense.paymentMethod, 'bank_transfer');
    });
  });

  group('ProductBatch', () {
    test('flags expiring and expired batches', () {
      final expired = ProductBatch.fromMap({
        'id': 'b1',
        'product_id': 'p1',
        'product_name': 'Milk',
        'qty': '5',
        'expiry_date':
            DateTime.now().subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
      });
      expect(expired.isExpired, isTrue);

      final okay = ProductBatch.fromMap({
        'id': 'b2',
        'product_id': 'p2',
        'product_name': 'Rice',
        'qty': '50',
        'expiry_date':
            DateTime.now().add(const Duration(days: 200)).toIso8601String().substring(0, 10),
      });
      expect(okay.isExpired, isFalse);
      expect(okay.expiringSoon, isFalse);
    });
  });
}
