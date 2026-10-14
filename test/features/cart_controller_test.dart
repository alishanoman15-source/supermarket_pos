import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/models/cart.dart';
import 'package:supermarket_pos/data/models/customer.dart';
import 'package:supermarket_pos/data/models/product.dart';
import 'package:supermarket_pos/features/pos/providers/cart_controller.dart';

Product _product({
  String id = 'p1',
  String name = 'Milk',
  String price = '100',
  String tax = '0',
  bool weightBased = false,
}) =>
    Product(
      id: id,
      businessId: 'b1',
      name: name,
      sellingPrice: Decimal.parse(price),
      taxRate: Decimal.parse(tax),
      isWeightBased: weightBased,
      trackBatch: false,
      reorderLevel: Decimal.zero,
      stock: Decimal.parse('10'),
      status: 'active',
    );

void main() {
  late ProviderContainer container;

  CartController controller() => container.read(cartControllerProvider.notifier);
  CartState cart() => container.read(cartControllerProvider);

  setUp(() {
    container = ProviderContainer();
    // Keep the auto-dispose provider alive for the duration of a test.
    container.listen(cartControllerProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  group('CartController — lines', () {
    test('adding the same product merges into one line', () {
      controller().addProduct(_product());
      controller().addProduct(_product());

      expect(cart().lines.length, 1);
      expect(cart().lines.single.qty, Decimal.fromInt(2));
      expect(cart().grandTotal, Decimal.parse('200'));
    });

    test('weight-based quantities are preserved exactly', () {
      controller().addProduct(_product(weightBased: true), qty: Decimal.parse('1.250'));

      expect(cart().lines.single.qty, Decimal.parse('1.250'));
      expect(cart().grandTotal, Decimal.parse('125'));
    });

    test('setting a quantity to zero removes the line', () {
      controller().addProduct(_product());
      controller().setQty('p1', Decimal.zero);

      expect(cart().isEmpty, isTrue);
    });

    test('decrement past one removes the line', () {
      controller().addProduct(_product());
      controller().decrement('p1');

      expect(cart().isEmpty, isTrue);
    });
  });

  group('CartController — discounts', () {
    test('line discount reduces the line net and the grand total', () {
      controller().addProduct(_product(price: '100'));
      controller().setLineDiscount('p1', Decimal.parse('15'));

      expect(cart().lines.single.net, Decimal.parse('85'));
      expect(cart().grandTotal, Decimal.parse('85'));
    });

    test('cart discount stacks on top of line discounts', () {
      controller().addProduct(_product(price: '100'));
      controller().setLineDiscount('p1', Decimal.parse('10'));
      controller().setCartDiscount(Decimal.parse('5'));

      expect(cart().discountTotal, Decimal.parse('15'));
      expect(cart().grandTotal, Decimal.parse('85'));
    });

    test('negative discounts are clamped to zero', () {
      controller().setCartDiscount(Decimal.parse('-20'));
      expect(cart().cartDiscount, Decimal.zero);
    });
  });

  group('CartController — price override', () {
    test('override flags the line but keeps the catalogue price', () {
      controller().addProduct(_product(price: '100'));
      controller().setPriceOverride('p1', Decimal.parse('80'));

      final line = cart().lines.single;
      expect(line.unitPrice, Decimal.parse('80'));
      expect(line.basePrice, Decimal.parse('100'));
      expect(line.isPriceOverridden, isTrue);
      expect(cart().grandTotal, Decimal.parse('80'));
    });
  });

  group('CartController — tax', () {
    test('exclusive tax is added on top of the net', () {
      controller().addProduct(_product(price: '100', tax: '17'));

      expect(cart().taxTotal, Decimal.parse('17'));
      expect(cart().grandTotal, Decimal.parse('117'));
    });

    test('inclusive tax is already inside the price', () {
      controller().addProduct(_product(price: '117', tax: '17'));
      controller().setTaxInclusive(true);

      expect(cart().taxTotal, Decimal.parse('17'));
      expect(cart().grandTotal, Decimal.parse('117'));
    });
  });

  group('CartController — customer', () {
    final customer = Customer(
      id: 'c1',
      name: 'Ali',
      loyaltyPoints: Decimal.zero,
      creditLimit: Decimal.zero,
    );

    test('attaching a customer records id and name', () {
      controller().setCustomer(customer);

      expect(cart().customerId, 'c1');
      expect(cart().customerName, 'Ali');
    });

    test('clearing the customer resets to guest', () {
      controller().setCustomer(customer);
      controller().setCustomer(null);

      expect(cart().customerId, isNull);
      expect(cart().customerName, isNull);
    });
  });
}
