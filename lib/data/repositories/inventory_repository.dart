import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/inventory.dart';
import '../models/product_batch.dart';

/// All writes go through transactional RPCs; clients never touch
/// `inventories` (select is revoked) — reads use `inventory_view` (SPEC §82).
class InventoryRepository {
  final SupabaseClient _client;

  const InventoryRepository(this._client);

  static const int pageSize = 50;

  // --- On-hand list ---------------------------------------------------------
  Future<List<StockRecord>> fetchOnHand({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('inventory_view').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,sku.ilike.%$term%,barcode.eq.$term');
      }
      final rows = await request
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);
      return rows.map((r) => StockRecord.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<StockRecord?> fetchOnHandForProduct(String productId) async {
    try {
      final row = await _client
          .from('inventory_view')
          .select()
          .eq('product_id', productId)
          .maybeSingle();
      return row == null ? null : StockRecord.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Batches / expiry -----------------------------------------------------
  Future<List<ProductBatch>> fetchBatches({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('product_batches').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.ilike('batch_no', '%$term%');
      final rows = await request.order('expiry_date', ascending: true).range(offset, offset + limit - 1);
      final items = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      // `authenticated` has no SELECT on public.products (cost protection), so
      // embedded `products(name)` is rejected — resolve names via the POS view.
      final names =
          await _productNames(items.map((b) => b['product_id'] as String).toSet());
      return items
          .map((b) => ProductBatch.fromMap({
                ...b,
                'product_name': names[b['product_id']] ?? '',
              }))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Map<String, String>> _productNames(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client
        .from('product_pos_view')
        .select('id,name')
        .inFilter('id', ids.toList());
    return {
      for (final r in rows) (r['id'] as String): (r['name'] as String?) ?? '',
    };
  }

  // --- Movement timeline ----------------------------------------------------
  Future<List<StockMovement>> fetchMovements(String productId, {int limit = 50}) async {
    try {
      final rows = await _client
          .from('stock_movements')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows.map((r) => StockMovement.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Adjustment -----------------------------------------------------------
  Future<void> adjustStock({
    required String productId,
    required Decimal qtyDelta,
    required String reason,
    String? idempotencyKey,
  }) async {
    try {
      await _client.rpc('adjust_stock', params: {
        'p_payload': {
          'product_id': productId,
          'qty_delta': qtyDelta.toString(),
          'reason': reason,
          'idempotency_key': idempotencyKey,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Stock counts ---------------------------------------------------------
  Future<List<StockCount>> fetchCounts() async {
    try {
      final rows =
          await _client.from('stock_counts').select().order('started_at', ascending: false).limit(50);
      return rows.map((r) => StockCount.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<StockCountItem>> fetchCountItems(String stockCountId) async {
    try {
      final rows = await _client
          .from('stock_count_items')
          .select()
          .eq('stock_count_id', stockCountId)
          .order('created_at', ascending: true);
      return rows.map((r) => StockCountItem.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<String> startStockCount({String? note}) async {
    try {
      final res = await _client.rpc('start_stock_count', params: {
        'p_payload': {if (note != null && note.isNotEmpty) 'note': note},
      });
      return Map<String, dynamic>.from((res as Map)['data'])['stock_count_id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> submitStockCount(String stockCountId, List<Map<String, dynamic>> items) async {
    try {
      await _client.rpc('submit_stock_count', params: {
        'p_stock_count_id': stockCountId,
        'p_items': items,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> approveStockCount(String stockCountId) async {
    try {
      await _client.rpc('approve_stock_count', params: {'p_stock_count_id': stockCountId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Transfers ------------------------------------------------------------
  Future<List<StockTransfer>> fetchTransfers() async {
    try {
      final rows =
          await _client.from('stock_transfers').select().order('created_at', ascending: false).limit(50);
      return rows.map((r) => StockTransfer.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> createTransfer({
    required String toBranchId,
    required List<Map<String, dynamic>> items,
    String? fromBranchId,
    String? note,
    String? idempotencyKey,
  }) async {
    try {
      await _client.rpc('transfer_stock', params: {
        'p_payload': {
          'from_branch_id': fromBranchId,
          'to_branch_id': toBranchId,
          'items': items,
          if (note != null && note.isNotEmpty) 'note': note,
          'idempotency_key': idempotencyKey,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> receiveTransfer(String transferId) async {
    try {
      await _client.rpc('receive_transfer', params: {'p_transfer_id': transferId});
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
