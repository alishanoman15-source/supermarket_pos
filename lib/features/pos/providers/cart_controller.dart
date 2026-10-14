import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/cart.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';

/// Owns the live cart for the POS terminal. State is immutable; every mutation
/// rebuilds totals (SPEC §87). Money/quantities are [Decimal] throughout.
class CartController extends AutoDisposeNotifier<CartState> {
  @override
  CartState build() => CartState();

  void setTaxInclusive(bool value) {
    if (state.taxInclusive == value) return;
    state = state.copyWith(taxInclusive: value);
  }

  /// Adds [product] or increments an existing line. [qty] defaults to 1 and is
  /// used by the weight-based quantity prompt (SPEC §5).
  void addProduct(Product product, {Decimal? qty}) {
    final add = qty ?? Decimal.one;
    if (add <= Decimal.zero) return;

    final existing = state.lineFor(product.id);
    if (existing == null) {
      state = state.copyWith(lines: [
        ...state.lines,
        CartLine(
          productId: product.id,
          name: product.name,
          sku: product.sku,
          barcode: product.barcode,
          unitPrice: product.sellingPrice,
          basePrice: product.sellingPrice,
          qty: add,
          taxRate: product.taxRate,
          isWeightBased: product.isWeightBased,
        ),
      ]);
    } else {
      setQty(product.id, existing.qty + add);
    }
  }

  void setQty(String productId, Decimal qty) {
    if (qty <= Decimal.zero) {
      removeLine(productId);
      return;
    }
    state = state.copyWith(lines: [
      for (final line in state.lines)
        if (line.productId == productId) line.copyWith(qty: qty) else line,
    ]);
  }

  void increment(String productId) {
    final line = state.lineFor(productId);
    if (line == null) return;
    setQty(productId, line.qty + Decimal.one);
  }

  void decrement(String productId) {
    final line = state.lineFor(productId);
    if (line == null) return;
    setQty(productId, line.qty - Decimal.one);
  }

  void removeLine(String productId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.productId != productId).toList(),
    );
  }

  void setLineDiscount(String productId, Decimal discount) {
    final safe = discount < Decimal.zero ? Decimal.zero : discount;
    state = state.copyWith(lines: [
      for (final line in state.lines)
        if (line.productId == productId) line.copyWith(discount: safe) else line,
    ]);
  }

  void setPriceOverride(String productId, Decimal price) {
    if (price < Decimal.zero) return;
    state = state.copyWith(lines: [
      for (final line in state.lines)
        if (line.productId == productId) line.copyWith(unitPrice: price) else line,
    ]);
  }

  void setCartDiscount(Decimal discount) {
    state = state.copyWith(
      cartDiscount: discount < Decimal.zero ? Decimal.zero : discount,
    );
  }

  void setCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(clearCustomer: true);
    } else {
      state = state.copyWith(customerId: customer.id, customerName: customer.name);
    }
  }

  void setNote(String note) => state = state.copyWith(note: note);

  void clear() {
    final inclusive = state.taxInclusive;
    state = CartState(taxInclusive: inclusive);
  }

  /// Restores a held cart / parked snapshot.
  void restore(CartState cart) => state = cart;
}

final cartControllerProvider =
    AutoDisposeNotifierProvider<CartController, CartState>(CartController.new);
