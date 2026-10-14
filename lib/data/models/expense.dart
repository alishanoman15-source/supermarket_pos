import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// An expense (SPEC §17). Table `expenses`.
class Expense {
  final String id;
  final String branchId;
  final String? categoryId;
  final String? categoryName;
  final Decimal amount;
  final DateTime paidAt;
  final String paymentMethod;
  final String? payee;
  final String? note;
  final String status;

  const Expense({
    required this.id,
    required this.branchId,
    required this.amount,
    required this.paidAt,
    required this.paymentMethod,
    required this.status,
    this.categoryId,
    this.categoryName,
    this.payee,
    this.note,
  });

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        categoryId: map['category_id'] as String?,
        categoryName: map['category_name'] as String?,
        amount: decimalFrom(map['amount']),
        paidAt: map['paid_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['paid_at'] as String).toLocal(),
        paymentMethod: (map['payment_method'] as String?) ?? 'cash',
        payee: map['payee'] as String?,
        note: map['note'] as String?,
        status: (map['status'] as String?) ?? 'active',
      );
}

/// An expense category (SPEC §17). `business_id` null = system category.
class ExpenseCategory {
  final String id;
  final String? businessId;
  final String name;
  final bool isSystem;

  const ExpenseCategory({
    required this.id,
    required this.name,
    this.businessId,
    this.isSystem = false,
  });

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as String,
        businessId: map['business_id'] as String?,
        name: (map['name'] as String?) ?? '',
        isSystem: (map['is_system'] as bool?) ?? false,
      );
}
