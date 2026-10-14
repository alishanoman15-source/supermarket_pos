import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A supplier (SPEC §69). Table `suppliers`.
class Supplier {
  final String id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final Decimal openingBalance;
  final String status;
  final DateTime createdAt;

  const Supplier({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.status,
    required this.createdAt,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
  });

  bool get isActive => status == 'active';

  factory Supplier.fromMap(Map<String, dynamic> map) => Supplier(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        contactPerson: map['contact_person'] as String?,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        address: map['address'] as String?,
        openingBalance: decimalFrom(map['opening_balance']),
        status: (map['status'] as String?) ?? 'active',
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

/// A supplier payment row (SPEC §77). Table `supplier_payments`.
class SupplierPayment {
  final String id;
  final String supplierId;
  final String? purchaseId;
  final String method;
  final Decimal amount;
  final String? reference;
  final String? note;
  final DateTime paidAt;

  const SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.method,
    required this.amount,
    required this.paidAt,
    this.purchaseId,
    this.reference,
    this.note,
  });

  factory SupplierPayment.fromMap(Map<String, dynamic> map) => SupplierPayment(
        id: map['id'] as String,
        supplierId: map['supplier_id'] as String,
        purchaseId: map['purchase_id'] as String?,
        method: (map['method'] as String?) ?? 'cash',
        amount: decimalFrom(map['amount']),
        reference: map['reference'] as String?,
        note: map['note'] as String?,
        paidAt: map['paid_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['paid_at'] as String).toLocal(),
      );
}
