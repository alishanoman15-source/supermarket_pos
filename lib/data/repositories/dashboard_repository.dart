import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/dashboard_kpis.dart';

class DashboardRepository {
  final SupabaseClient _client;

  const DashboardRepository(this._client);

  Future<DashboardKpis> fetchKpis({DateTime? from, DateTime? to, String? branchId}) async {
    try {
      final res = await _client.rpc('dashboard_kpis', params: {
        'p_from': from?.toUtc().toIso8601String(),
        'p_to': to?.toUtc().toIso8601String(),
        'p_branch': branchId,
      });
      final data = Map<String, dynamic>.from((res as Map)['data'] as Map);
      return DashboardKpis.fromData(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
