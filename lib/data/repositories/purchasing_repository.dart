import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/purchase.dart';

/// Purchase orders, goods receiving and purchase bills (SPEC §77).
/// All mutations go through the transactional RPCs.
class PurchasingRepository {
  final SupabaseClient _client;

  const PurchasingRepository(this._client);

  static const int pageSize = 50;

  Future<List<PurchaseOrder>> fetchPurchaseOrders({
    int offset = 0,
    int limit = pageSize,
    String? query,
    String? status,
  }) async {
    try {
      var request = _client.from('purchase_orders').select('*, supplier:suppliers(name)');
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.ilike('po_number', '%$term%');
      if (status != null && status.isNotEmpty) request = request.eq('status', status);
      final rows = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        final supplier = map['supplier'];
        if (supplier is Map) map['supplier_name'] = supplier['name'];
        return PurchaseOrder.fromMap(map);
      }).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<PurchaseOrder?> fetchPurchaseOrder(String id) async {
    try {
      final row = await _client
          .from('purchase_orders')
          .select('*, supplier:suppliers(name)')
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      final map = Map<String, dynamic>.from(row);
      final supplier = map['supplier'];
      if (supplier is Map) map['supplier_name'] = supplier['name'];
      return PurchaseOrder.fromMap(map);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<PurchaseOrderItem>> fetchPurchaseOrderItems(String purchaseOrderId) async {
    try {
      final rows = await _client
          .from('purchase_order_items')
          .select()
          .eq('purchase_order_id', purchaseOrderId)
          .order('created_at', ascending: true);
      final items = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      final names = await _productNames(items.map((i) => i['product_id'] as String).toSet());
      return items
          .map((i) => PurchaseOrderItem.fromMap({...i, 'product_name': names[i['product_id']] ?? ''}))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> createPurchaseOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    String? branchId,
    String? expectedAt,
    String? note,
  }) async {
    try {
      await _client.rpc('create_purchase_order', params: {
        'p_payload': {
          'supplier_id': supplierId,
          'branch_id': ?branchId,
          'expected_at': ?expectedAt,
          if (note != null && note.isNotEmpty) 'note': note,
          'items': items,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> approvePurchaseOrder(String poId) async {
    try {
      await _client.rpc('approve_purchase_order', params: {'p_po_id': poId});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Receive goods against a PO or directly (SPEC §55, §77).
  Future<void> receivePurchase({
    required List<Map<String, dynamic>> items,
    String? purchaseOrderId,
    String? supplierId,
    String? branchId,
    String? billNumber,
    String? dueAt,
    String? note,
    String? idempotencyKey,
  }) async {
    try {
      await _client.rpc('receive_purchase', params: {
        'p_payload': {
          'purchase_order_id': ?purchaseOrderId,
          'supplier_id': ?supplierId,
          'branch_id': ?branchId,
          if (billNumber != null && billNumber.isNotEmpty) 'bill_number': billNumber,
          if (dueAt != null && dueAt.isNotEmpty) 'due_at': dueAt,
          if (note != null && note.isNotEmpty) 'note': note,
          'idempotency_key': idempotencyKey,
          'items': items,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Purchase bills -------------------------------------------------------
  Future<List<Purchase>> fetchPurchases({
    int offset = 0,
    int limit = pageSize,
    String? query,
    String? status,
  }) async {
    try {
      var request = _client.from('purchases').select('*, supplier:suppliers(name)');
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.ilike('bill_number', '%$term%');
      if (status != null && status.isNotEmpty) request = request.eq('status', status);
      final rows = await request
          .order('received_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        final supplier = map['supplier'];
        if (supplier is Map) map['supplier_name'] = supplier['name'];
        return Purchase.fromMap(map);
      }).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<PurchaseItem>> fetchPurchaseItems(String purchaseId) async {
    try {
      final rows = await _client
          .from('purchase_items')
          .select()
          .eq('purchase_id', purchaseId)
          .order('created_at', ascending: true);
      final items = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      final names = await _productNames(items.map((i) => i['product_id'] as String).toSet());
      return items
          .map((i) => PurchaseItem.fromMap({...i, 'product_name': names[i['product_id']] ?? ''}))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> cancelPurchase(String purchaseId) async {
    try {
      await _client
          .from('purchases')
          .update({'status': 'cancelled'}).eq('id', purchaseId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Product names for a set of ids via the cost-safe POS view (products
  /// SELECT is revoked for clients).
  Future<Map<String, String>> _productNames(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await _client.from('product_pos_view').select('id,name').inFilter('id', ids.toList());
    return {
      for (final r in rows) (r['id'] as String): (r['name'] as String?) ?? '',
    };
  }
}
