import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

class StockRecord {
  final String productId;
  final String branchId;
  final Decimal onHand;
  final Decimal reserved;
  final String name;
  final String? sku;
  final String? barcode;
  final String? unitId;
  final Decimal reorderLevel;
  final bool isWeightBased;
  final bool isLow;
  final String status;

  const StockRecord({
    required this.productId,
    required this.branchId,
    required this.onHand,
    required this.reserved,
    required this.name,
    required this.reorderLevel,
    required this.isWeightBased,
    required this.isLow,
    required this.status,
    this.sku,
    this.barcode,
    this.unitId,
  });

  factory StockRecord.fromMap(Map<String, dynamic> map) => StockRecord(
        productId: map['product_id'] as String,
        branchId: map['branch_id'] as String,
        onHand: decimalFrom(map['on_hand']),
        reserved: decimalFrom(map['reserved']),
        name: (map['name'] as String?) ?? '',
        sku: map['sku'] as String?,
        barcode: map['barcode'] as String?,
        unitId: map['unit_id'] as String?,
        reorderLevel: decimalFrom(map['reorder_level']),
        isWeightBased: (map['is_weight_based'] as bool?) ?? false,
        isLow: (map['is_low'] as bool?) ?? false,
        status: (map['status'] as String?) ?? 'active',
      );
}

class StockMovement {
  final String id;
  final String productId;
  final String movementType;
  final Decimal qtyDelta;
  final Decimal qtyBefore;
  final Decimal qtyAfter;
  final String? reason;
  final String? refTable;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productId,
    required this.movementType,
    required this.qtyDelta,
    required this.qtyBefore,
    required this.qtyAfter,
    required this.createdAt,
    this.reason,
    this.refTable,
  });

  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: map['id'] as String,
        productId: map['product_id'] as String,
        movementType: (map['movement_type'] as String?) ?? '',
        qtyDelta: decimalFrom(map['qty_delta']),
        qtyBefore: decimalFrom(map['qty_before']),
        qtyAfter: decimalFrom(map['qty_after']),
        reason: map['reason'] as String?,
        refTable: map['ref_table'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      );
}

class StockCount {
  final String id;
  final String branchId;
  final String status; // draft | submitted | approved | cancelled
  final String? note;
  final DateTime startedAt;

  const StockCount({
    required this.id,
    required this.branchId,
    required this.status,
    required this.startedAt,
    this.note,
  });

  factory StockCount.fromMap(Map<String, dynamic> map) => StockCount(
        id: map['id'] as String,
        branchId: map['branch_id'] as String,
        status: (map['status'] as String?) ?? 'draft',
        note: map['note'] as String?,
        startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
      );
}

class StockCountItem {
  final String id;
  final String stockCountId;
  final String productId;
  final Decimal systemQty;
  final Decimal? countedQty;
  final Decimal? delta;

  const StockCountItem({
    required this.id,
    required this.stockCountId,
    required this.productId,
    required this.systemQty,
    this.countedQty,
    this.delta,
  });

  factory StockCountItem.fromMap(Map<String, dynamic> map) => StockCountItem(
        id: map['id'] as String,
        stockCountId: map['stock_count_id'] as String,
        productId: map['product_id'] as String,
        systemQty: decimalFrom(map['system_qty']),
        countedQty: map['counted_qty'] == null ? null : decimalFrom(map['counted_qty']),
        delta: map['delta'] == null ? null : decimalFrom(map['delta']),
      );
}

class StockTransfer {
  final String id;
  final String fromBranchId;
  final String toBranchId;
  final String status; // in_transit | received | cancelled
  final String? note;
  final DateTime createdAt;
  final DateTime? receivedAt;

  const StockTransfer({
    required this.id,
    required this.fromBranchId,
    required this.toBranchId,
    required this.status,
    required this.createdAt,
    this.note,
    this.receivedAt,
  });

  factory StockTransfer.fromMap(Map<String, dynamic> map) => StockTransfer(
        id: map['id'] as String,
        fromBranchId: map['from_branch_id'] as String,
        toBranchId: map['to_branch_id'] as String,
        status: (map['status'] as String?) ?? 'in_transit',
        note: map['note'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
        receivedAt: map['received_at'] == null
            ? null
            : DateTime.parse(map['received_at'] as String).toLocal(),
      );
}

class StockTransferItem {
  final String id;
  final String transferId;
  final String productId;
  final Decimal qty;

  const StockTransferItem({
    required this.id,
    required this.transferId,
    required this.productId,
    required this.qty,
  });

  factory StockTransferItem.fromMap(Map<String, dynamic> map) => StockTransferItem(
        id: map['id'] as String,
        transferId: map['transfer_id'] as String,
        productId: map['product_id'] as String,
        qty: decimalFrom(map['qty']),
      );
}
