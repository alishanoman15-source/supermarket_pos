import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A tracked batch / expiry row (SPEC §73). Table `product_batches`.
class ProductBatch {
  final String id;
  final String productId;
  final String productName;
  final String? batchNo;
  final DateTime? expiryDate;
  final Decimal qty;

  const ProductBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    this.batchNo,
    this.expiryDate,
  });

  bool get isExpired =>
      expiryDate != null && expiryDate!.isBefore(DateTime.now());

  bool get expiringSoon {
    if (expiryDate == null) return false;
    final days = expiryDate!.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 30;
  }

  factory ProductBatch.fromMap(Map<String, dynamic> map) => ProductBatch(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        productName: (map['product_name'] as String?) ?? '',
        batchNo: map['batch_no'] as String?,
        expiryDate: map['expiry_date'] == null
            ? null
            : DateTime.parse(map['expiry_date'] as String),
        qty: decimalFrom(map['qty']),
      );
}
