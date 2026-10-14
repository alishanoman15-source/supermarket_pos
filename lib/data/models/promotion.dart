import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A promotion (SPEC §16). Table `promotions`.
class Promotion {
  final String id;
  final String? branchId;
  final String name;
  final String promoType; // percent_off | fixed_off | buy_x_get_y | price_per_unit
  final Decimal value;
  final Decimal minQty;
  final Decimal freeQty;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isStackable;
  final String status;

  const Promotion({
    required this.id,
    required this.name,
    required this.promoType,
    required this.value,
    required this.minQty,
    required this.freeQty,
    required this.isStackable,
    required this.status,
    this.branchId,
    this.startsAt,
    this.endsAt,
  });

  bool get isActive => status == 'active';

  bool get isLive {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return isActive;
  }

  factory Promotion.fromMap(Map<String, dynamic> map) => Promotion(
        id: map['id'] as String,
        branchId: map['branch_id'] as String?,
        name: (map['name'] as String?) ?? '',
        promoType: (map['promo_type'] as String?) ?? 'percent_off',
        value: decimalFrom(map['value']),
        minQty: decimalFrom(map['min_qty']),
        freeQty: decimalFrom(map['free_qty']),
        startsAt: map['starts_at'] == null
            ? null
            : DateTime.parse(map['starts_at'] as String).toLocal(),
        endsAt: map['ends_at'] == null
            ? null
            : DateTime.parse(map['ends_at'] as String).toLocal(),
        isStackable: (map['is_stackable'] as bool?) ?? false,
        status: (map['status'] as String?) ?? 'active',
      );
}
