import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/product.dart';

/// Reads products through `product_pos_view` (cost-safe). Writes go directly to
/// `products`, where RLS + permission checks guard the row (SPEC §71).
class ProductRepository {
  final SupabaseClient _client;

  const ProductRepository(this._client);

  static const int pageSize = 50;

  Future<List<Product>> fetchPage({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('product_pos_view').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,sku.ilike.%$term%,barcode.eq.$term');
      }
      final rows = await request.order('name', ascending: true).range(offset, offset + limit - 1);
      return rows.map((r) => Product.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Exact barcode lookup for POS scan-to-cart (SPEC §10 step 2).
  Future<Product?> fetchByBarcode(String barcode) async {
    try {
      final row = await _client
          .from('product_pos_view')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();
      return row == null ? null : Product.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Exact SKU lookup (scanner fallback when a barcode is not matched).
  Future<Product?> fetchBySku(String sku) async {
    try {
      final row = await _client
          .from('product_pos_view')
          .select()
          .eq('sku', sku)
          .maybeSingle();
      return row == null ? null : Product.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Product?> fetchById(String id) async {
    try {
      final row = await _client.from('product_pos_view').select().eq('id', id).maybeSingle();
      return row == null ? null : Product.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Detail projection. Cost (`purchase_price`) is present only for holders of
  /// `products.view_cost`; otherwise the column comes back null (SPEC §71).
  Future<Product?> fetchFullById(String id) async {
    try {
      final row = await _client.from('product_full_view').select().eq('id', id).maybeSingle();
      return row == null ? null : Product.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> create({required String businessId, required Map<String, dynamic> values}) async {
    try {
      // No `.select()`: authenticated has no SELECT privilege on products.
      await _client.from('products').insert({'business_id': businessId, ...values});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> update(String id, Map<String, dynamic> values) async {
    try {
      await _client.from('products').update(values).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> archive(String id) async {
    try {
      await _client.from('products').update({'status': 'archived', 'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
