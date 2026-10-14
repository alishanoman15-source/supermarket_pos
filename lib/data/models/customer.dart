import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A customer record (SPEC §70).
class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final Decimal loyaltyPoints;
  final Decimal creditLimit;

  const Customer({
    required this.id,
    required this.name,
    required this.loyaltyPoints,
    required this.creditLimit,
    this.phone,
    this.email,
  });

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        loyaltyPoints: decimalFrom(map['loyalty_points']),
        creditLimit: decimalFrom(map['credit_limit']),
      );
}
