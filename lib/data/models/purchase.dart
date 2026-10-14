import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A purchase order (SPEC §77). Table `purchase_orders`.
class PurchaseOrder {
  final String id;
  final String branchId;
  final String supplierId;
  final String supplierName;
  final String? poNumber;
  final String status;
  final DateTime? expectedAt;
  final Decimal subtotal;
  final Decimal taxTotal;
  final Decimal total;
  final String? note;
  final DateTime createdAt;

  const PurchaseOrder({
    required this.id,
    required this.branchId,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.taxTotal,
    required this.total,
    required this.createdAt,
    this.poNumber,
    this.expectedAt,
    this.note,
  });

  bool get isDraft => status == 'draft';
  bool get canReceive => status == 'approved' || status == 'partially_received';

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) => PurchaseOrder(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        supplierId: map['supplier_id'] as String,
        supplierName:
            (map['supplier_name'] as String?) ?? (map['supplier'] is Map ? '' : ''),
        poNumber: map['po_number'] as String?,
        status: (map['status'] as String?) ?? 'draft',
        expectedAt: map['expected_at'] == null
            ? null
            : DateTime.parse(map['expected_at'] as String),
        subtotal: decimalFrom(map['subtotal']),
        taxTotal: decimalFrom(map['tax_total']),
        total: decimalFrom(map['total']),
        note: map['note'] as String?,
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

/// A line on a purchase order (SPEC §77). Table `purchase_order_items`.
class PurchaseOrderItem {
  final String id;
  final String productId;
  final String productName;
  final Decimal qty;
  final Decimal receivedQty;
  final Decimal unitCost;
  final Decimal taxRate;
  final Decimal lineTotal;

  const PurchaseOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.receivedQty,
    required this.unitCost,
    required this.taxRate,
    required this.lineTotal,
  });

  double get progress {
    if (qty <= Decimal.zero) return 0;
    return (receivedQty / qty).toDouble().clamp(0, 1);
  }

  factory PurchaseOrderItem.fromMap(Map<String, dynamic> map) => PurchaseOrderItem(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        productName: (map['product_name'] as String?) ?? '',
        qty: decimalFrom(map['qty']),
        receivedQty: decimalFrom(map['received_qty']),
        unitCost: decimalFrom(map['unit_cost']),
        taxRate: decimalFrom(map['tax_rate']),
        lineTotal: decimalFrom(map['line_total']),
      );
}

/// A received purchase bill (SPEC §77). Table `purchases`.
class Purchase {
  final String id;
  final String supplierId;
  final String supplierName;
  final String? billNumber;
  final String status; // unpaid | partially_paid | paid | cancelled
  final Decimal subtotal;
  final Decimal taxTotal;
  final Decimal total;
  final Decimal paidTotal;
  final DateTime receivedAt;
  final DateTime? dueAt;
  final String? note;

  const Purchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.status,
    required this.subtotal,
    required this.taxTotal,
    required this.total,
    required this.paidTotal,
    required this.receivedAt,
    this.billNumber,
    this.dueAt,
    this.note,
  });

  Decimal get balance => total - paidTotal;

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
        id: map['id'] as String,
        supplierId: map['supplier_id'] as String,
        supplierName: (map['supplier_name'] as String?) ?? '',
        billNumber: map['bill_number'] as String?,
        status: (map['status'] as String?) ?? 'unpaid',
        subtotal: decimalFrom(map['subtotal']),
        taxTotal: decimalFrom(map['tax_total']),
        total: decimalFrom(map['total']),
        paidTotal: decimalFrom(map['paid_total']),
        receivedAt: map['received_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['received_at'] as String).toLocal(),
        dueAt: map['due_at'] == null ? null : DateTime.parse(map['due_at'] as String),
        note: map['note'] as String?,
      );
}

/// A line on a purchase bill. Table `purchase_items`.
class PurchaseItem {
  final String id;
  final String productId;
  final String productName;
  final Decimal qty;
  final Decimal unitCost;
  final Decimal lineTotal;

  const PurchaseItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitCost,
    required this.lineTotal,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> map) => PurchaseItem(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        productName: (map['product_name'] as String?) ?? '',
        qty: decimalFrom(map['qty']),
        unitCost: decimalFrom(map['unit_cost']),
        lineTotal: decimalFrom(map['line_total']),
      );
}
