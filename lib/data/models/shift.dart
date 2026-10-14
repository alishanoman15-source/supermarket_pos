import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A POS shift (SPEC §78). Table is `pos_shifts`.
class Shift {
  final String id;
  final String branchId;
  final String status; // open | closed
  final Decimal openingFloat;
  final Decimal? closingCounted;
  final Decimal? expectedCash;
  final Decimal? variance;
  final String? varianceReason;
  final DateTime openedAt;
  final DateTime? closedAt;

  const Shift({
    required this.id,
    required this.branchId,
    required this.status,
    required this.openingFloat,
    required this.openedAt,
    this.closingCounted,
    this.expectedCash,
    this.variance,
    this.varianceReason,
    this.closedAt,
  });

  bool get isOpen => status == 'open';

  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        status: (map['status'] as String?) ?? 'open',
        openingFloat: decimalFrom(map['opening_float']),
        closingCounted: map['closing_counted'] == null ? null : decimalFrom(map['closing_counted']),
        expectedCash: map['expected_cash'] == null ? null : decimalFrom(map['expected_cash']),
        variance: map['variance'] == null ? null : decimalFrom(map['variance']),
        varianceReason: map['variance_reason'] as String?,
        openedAt: DateTime.parse(map['opened_at'] as String).toLocal(),
        closedAt: map['closed_at'] == null
            ? null
            : DateTime.parse(map['closed_at'] as String).toLocal(),
      );
}

class CashMovement {
  final String id;
  final String shiftId;
  final String type; // float | sale | refund | drawer_in | drawer_out
  final Decimal amount;
  final String? note;
  final DateTime createdAt;

  const CashMovement({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  factory CashMovement.fromMap(Map<String, dynamic> map) => CashMovement(
        id: map['id'] as String,
        shiftId: map['shift_id'] as String,
        type: (map['type'] as String?) ?? '',
        amount: decimalFrom(map['amount']),
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
