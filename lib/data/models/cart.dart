import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A single cart line. Money and quantities are [Decimal] only (SPEC §87).
class CartLine {
  final String productId;
  final String name;
  final String? sku;
  final String? barcode;
  final Decimal unitPrice; // effective price (may be overridden)
  final Decimal basePrice; // catalogue selling price
  final Decimal qty;
  final Decimal discount;
  final Decimal taxRate;
  final bool isWeightBased;

  CartLine({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.basePrice,
    required this.qty,
    required this.taxRate,
    this.sku,
    this.barcode,
    Decimal? discount,
    this.isWeightBased = false,
  }) : discount = discount ?? Decimal.zero;

  bool get isPriceOverridden => unitPrice != basePrice;

  Decimal get gross => roundMoney(qty * unitPrice);
  Decimal get net {
    final value = gross - discount;
    return value < Decimal.zero ? Decimal.zero : value;
  }

  CartLine copyWith({
    Decimal? unitPrice,
    Decimal? qty,
    Decimal? discount,
  }) =>
      CartLine(
        productId: productId,
        name: name,
        sku: sku,
        barcode: barcode,
        unitPrice: unitPrice ?? this.unitPrice,
        basePrice: basePrice,
        qty: qty ?? this.qty,
        discount: discount ?? this.discount,
        taxRate: taxRate,
        isWeightBased: isWeightBased,
      );

  Map<String, dynamic> toPayload() => {
        'product_id': productId,
        'qty': qty.toString(),
        if (discount > Decimal.zero) 'discount': discount.toString(),
        if (isPriceOverridden) 'unit_price': unitPrice.toString(),
      };

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'unit_price': unitPrice.toString(),
        'base_price': basePrice.toString(),
        'qty': qty.toString(),
        'discount': discount.toString(),
        'tax_rate': taxRate.toString(),
        'is_weight_based': isWeightBased,
      };

  factory CartLine.fromJson(Map<String, dynamic> map) => CartLine(
        productId: map['product_id'] as String,
        name: (map['name'] as String?) ?? '',
        sku: map['sku'] as String?,
        barcode: map['barcode'] as String?,
        unitPrice: decimalFrom(map['unit_price']),
        basePrice: decimalFrom(map['base_price']),
        qty: decimalFrom(map['qty']),
        discount: decimalFrom(map['discount']),
        taxRate: decimalFrom(map['tax_rate']),
        isWeightBased: (map['is_weight_based'] as bool?) ?? false,
      );
}

/// One tender line on the payment screen (split payments supported, §10).
class PaymentLine {
  final String method; // cash | card | mobile_wallet | other
  final Decimal amount;
  final String? reference;

  const PaymentLine({required this.method, required this.amount, this.reference});

  Map<String, dynamic> toPayload() => {
        'method': method,
        'amount': amount.toString(),
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
      };
}

/// Immutable cart snapshot driving the POS terminal. All totals are recomputed
/// by `complete_sale` server-side; these are for display and change preview.
class CartState {
  final List<CartLine> lines;
  final String? customerId;
  final String? customerName;
  final Decimal cartDiscount;
  final String note;
  final bool taxInclusive;

  CartState({
    this.lines = const [],
    this.customerId,
    this.customerName,
    Decimal? cartDiscount,
    this.note = '',
    this.taxInclusive = false,
  }) : cartDiscount = cartDiscount ?? Decimal.zero;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  CartLine? lineFor(String productId) {
    for (final line in lines) {
      if (line.productId == productId) return line;
    }
    return null;
  }

  Decimal get subtotal =>
      lines.fold(Decimal.zero, (sum, line) => sum + line.gross);

  Decimal get lineDiscountTotal =>
      lines.fold(Decimal.zero, (sum, line) => sum + line.discount);

  Decimal get discountTotal => lineDiscountTotal + cartDiscount;

  /// Tax per line mirrors `complete_sale` (inclusive vs exclusive, §30).
  Decimal _taxFor(CartLine line) {
    final net = line.net;
    if (taxInclusive) {
      final factor = Decimal.one + divideDecimal(line.taxRate, hundred);
      final base = divideDecimal(net, factor);
      return roundMoney(net - base);
    }
    final product = divideDecimal(net * line.taxRate, hundred);
    return roundMoney(product);
  }

  Decimal get taxTotal =>
      lines.fold(Decimal.zero, (sum, line) => sum + _taxFor(line));

  Decimal get grandTotal {
    final net = subtotal - lineDiscountTotal - cartDiscount;
    // Inclusive prices already embed tax, so it is only added on top when
    // pricing is exclusive. This mirrors `complete_sale` server-side (SPEC §30).
    final value = taxInclusive ? net : net + taxTotal;
    return value < Decimal.zero ? Decimal.zero : value;
  }

  int get lineCount => lines.length;

  Decimal get itemCount => lines.fold(Decimal.zero, (sum, line) => sum + line.qty);

  CartState copyWith({
    List<CartLine>? lines,
    String? customerId,
    String? customerName,
    bool clearCustomer = false,
    Decimal? cartDiscount,
    String? note,
    bool? taxInclusive,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        customerId: clearCustomer ? null : (customerId ?? this.customerId),
        customerName: clearCustomer ? null : (customerName ?? this.customerName),
        cartDiscount: cartDiscount ?? this.cartDiscount,
        note: note ?? this.note,
        taxInclusive: taxInclusive ?? this.taxInclusive,
      );

  List<Map<String, dynamic>> get itemsPayload =>
      lines.map((line) => line.toPayload()).toList();

  Map<String, dynamic> toJson() => {
        'lines': lines.map((line) => line.toJson()).toList(),
        'customer_id': customerId,
        'customer_name': customerName,
        'cart_discount': cartDiscount.toString(),
        'note': note,
        'tax_inclusive': taxInclusive,
      };

  factory CartState.fromJson(Map<String, dynamic> map) => CartState(
        lines: ((map['lines'] as List?) ?? const [])
            .map((e) => CartLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        customerId: map['customer_id'] as String?,
        customerName: map['customer_name'] as String?,
        cartDiscount: decimalFrom(map['cart_discount']),
        note: (map['note'] as String?) ?? '',
        taxInclusive: (map['tax_inclusive'] as bool?) ?? false,
      );
}
