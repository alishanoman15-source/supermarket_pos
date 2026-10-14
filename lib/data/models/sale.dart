import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// A completed sale header (SPEC §75). Read from `public.sales`.
class Sale {
  final String id;
  final String branchId;
  final String invoiceNumber;
  final String? shiftId;
  final String? cashierId;
  final String? customerId;
  final Decimal subtotal;
  final Decimal discountTotal;
  final Decimal taxTotal;
  final Decimal grandTotal;
  final Decimal amountPaid;
  final Decimal changeDue;
  final String status; // completed | cancelled | partially_returned | returned
  final String? note;
  final DateTime soldAt;

  const Sale({
    required this.id,
    required this.branchId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeDue,
    required this.status,
    required this.soldAt,
    this.shiftId,
    this.cashierId,
    this.customerId,
    this.note,
  });

  factory Sale.fromMap(Map<String, dynamic> map) => Sale(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        invoiceNumber: (map['invoice_number'] as String?) ?? '',
        shiftId: map['shift_id'] as String?,
        cashierId: map['cashier_id'] as String?,
        customerId: map['customer_id'] as String?,
        subtotal: decimalFrom(map['subtotal']),
        discountTotal: decimalFrom(map['discount_total']),
        taxTotal: decimalFrom(map['tax_total']),
        grandTotal: decimalFrom(map['grand_total']),
        amountPaid: decimalFrom(map['amount_paid']),
        changeDue: decimalFrom(map['change_due']),
        status: (map['status'] as String?) ?? 'completed',
        note: map['note'] as String?,
        soldAt: DateTime.parse(map['sold_at'] as String).toLocal(),
      );
}

/// Immutable historical line snapshot (SPEC §76).
class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String nameSnapshot;
  final String? skuSnapshot;
  final String? barcodeSnapshot;
  final Decimal qty;
  final Decimal unitPrice;
  final Decimal costAtSale;
  final Decimal discount;
  final Decimal taxRate;
  final Decimal taxAmount;
  final Decimal lineTotal;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.nameSnapshot,
    required this.qty,
    required this.unitPrice,
    required this.costAtSale,
    required this.discount,
    required this.taxRate,
    required this.taxAmount,
    required this.lineTotal,
    this.skuSnapshot,
    this.barcodeSnapshot,
  });

  factory SaleItem.fromMap(Map<String, dynamic> map) => SaleItem(
        id: map['id'] as String,
        saleId: map['sale_id'] as String,
        productId: map['product_id'] as String,
        nameSnapshot: (map['name_snapshot'] as String?) ?? '',
        skuSnapshot: map['sku_snapshot'] as String?,
        barcodeSnapshot: map['barcode_snapshot'] as String?,
        qty: decimalFrom(map['qty']),
        unitPrice: decimalFrom(map['unit_price']),
        costAtSale: decimalFrom(map['cost_at_sale']),
        discount: decimalFrom(map['discount']),
        taxRate: decimalFrom(map['tax_rate']),
        taxAmount: decimalFrom(map['tax_amount']),
        lineTotal: decimalFrom(map['line_total']),
      );
}

/// One tender line of a (possibly split) payment (SPEC §75).
class SalePayment {
  final String id;
  final String saleId;
  final String method; // cash | card | mobile_wallet | other
  final Decimal amount;
  final String? reference;

  const SalePayment({
    required this.id,
    required this.saleId,
    required this.method,
    required this.amount,
    this.reference,
  });

  factory SalePayment.fromMap(Map<String, dynamic> map) => SalePayment(
        id: map['id'] as String,
        saleId: map['sale_id'] as String,
        method: (map['method'] as String?) ?? 'cash',
        amount: decimalFrom(map['amount']),
        reference: map['reference'] as String?,
      );
}

/// A post-sale return (SPEC §11). Read from `public.sale_returns`.
class SaleReturn {
  final String id;
  final String saleId;
  final String refundMethod;
  final Decimal totalRefund;
  final String reason;
  final DateTime createdAt;

  const SaleReturn({
    required this.id,
    required this.saleId,
    required this.refundMethod,
    required this.totalRefund,
    required this.reason,
    required this.createdAt,
  });

  factory SaleReturn.fromMap(Map<String, dynamic> map) => SaleReturn(
        id: map['id'] as String,
        saleId: map['sale_id'] as String,
        refundMethod: (map['refund_method'] as String?) ?? 'cash',
        totalRefund: decimalFrom(map['total_refund']),
        reason: (map['reason'] as String?) ?? '',
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

/// Aggregated result of a successful `complete_sale` RPC call.
class SaleResult {
  final String saleId;
  final String invoiceNumber;
  final Decimal subtotal;
  final Decimal discountTotal;
  final Decimal taxTotal;
  final Decimal grandTotal;
  final Decimal amountPaid;
  final Decimal changeDue;
  final bool duplicate;
  final bool pendingSync;
  final bool syncConflict;

  const SaleResult({
    required this.saleId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.grandTotal,
    required this.amountPaid,
    required this.changeDue,
    this.duplicate = false,
    this.pendingSync = false,
    this.syncConflict = false,
  });

  factory SaleResult.fromMap(Map<String, dynamic> map) => SaleResult(
        saleId: map['sale_id'] as String,
        invoiceNumber: (map['invoice_number'] as String?) ?? '',
        subtotal: decimalFrom(map['subtotal']),
        discountTotal: decimalFrom(map['discount_total']),
        taxTotal: decimalFrom(map['tax_total']),
        grandTotal: decimalFrom(map['grand_total']),
        amountPaid: decimalFrom(map['amount_paid']),
        changeDue: decimalFrom(map['change_due']),
        duplicate: (map['duplicate'] as bool?) ?? false,
      );
}
