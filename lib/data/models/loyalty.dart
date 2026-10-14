import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// An append-only loyalty ledger entry (SPEC §70). Table `loyalty_transactions`.
class LoyaltyTransaction {
  final String id;
  final String customerId;
  final String? saleId;
  final String type; // earn | redeem | adjust
  final Decimal points;
  final Decimal balanceAfter;
  final String? note;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.id,
    required this.customerId,
    required this.type,
    required this.points,
    required this.balanceAfter,
    required this.createdAt,
    this.saleId,
    this.note,
  });

  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) => LoyaltyTransaction(
        id: map['id'] as String,
        customerId: map['customer_id'] as String,
        saleId: map['sale_id'] as String?,
        type: (map['type'] as String?) ?? 'adjust',
        points: decimalFrom(map['points']),
        balanceAfter: decimalFrom(map['balance_after']),
        note: map['note'] as String?,
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
