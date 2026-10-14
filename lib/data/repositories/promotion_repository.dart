import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/promotion.dart';

/// Promotions CRUD (SPEC §16). Evaluation is done server-side by
/// `apply_promotion`; this repository only manages the definitions.
class PromotionRepository {
  final SupabaseClient _client;

  const PromotionRepository(this._client);

  static const int pageSize = 50;

  Future<List<Promotion>> fetchPromotions({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('promotions').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.ilike('name', '%$term%');
      final rows = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) => Promotion.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Promotion?> fetchPromotion(String id) async {
    try {
      final row = await _client.from('promotions').select().eq('id', id).maybeSingle();
      return row == null ? null : Promotion.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> savePromotion({
    String? id,
    required String businessId,
    required Map<String, dynamic> values,
  }) async {
    try {
      if (id == null) {
        await _client.from('promotions').insert({'business_id': businessId, ...values});
      } else {
        await _client.from('promotions').update(values).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> archivePromotion(String id) async {
    try {
      await _client.from('promotions').update({'status': 'inactive'}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
