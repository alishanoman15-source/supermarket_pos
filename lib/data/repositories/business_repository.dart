import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/branch.dart';
import '../models/business.dart';

class BusinessRepository {
  final SupabaseClient _client;

  const BusinessRepository(this._client);

  /// Atomic onboarding: business + first branch + owner role + sequences.
  /// Returns the new business id.
  Future<String> createBusinessWithOwner({
    required Map<String, dynamic> business,
    required Map<String, dynamic> branch,
  }) async {
    try {
      final res = await _client.rpc('create_business_with_owner', params: {
        'p_business': business,
        'p_branch': branch,
      });
      final data = Map<String, dynamic>.from((res as Map)['data'] as Map);
      return data['business_id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Business?> fetchById(String businessId) async {
    try {
      final row = await _client.from('businesses').select().eq('id', businessId).maybeSingle();
      return row == null ? null : Business.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<Branch>> fetchBranches(String businessId) async {
    try {
      final rows = await _client
          .from('branches')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true);
      return rows.map((r) => Branch.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // -----------------------------------------------------------------------
  // Branch administration (SPEC §6, §86 screens 58–59). RLS gates every write
  // on `branches.manage`; nothing here is trusted from the client.
  // -----------------------------------------------------------------------

  Future<void> createBranch({
    required String businessId,
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      await _client.from('branches').insert({
        'business_id': businessId,
        'name': name.trim(),
        'address': _blankToNull(address),
        'phone': _blankToNull(phone),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateBranch({
    required String id,
    required String name,
    String? address,
    String? phone,
    String status = 'active',
  }) async {
    try {
      await _client.from('branches').update({
        'name': name.trim(),
        'address': _blankToNull(address),
        'phone': _blankToNull(phone),
        'status': status,
        'is_active': status == 'active',
      }).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<PosTerminal>> fetchTerminals({String? branchId}) async {
    try {
      final rows = branchId == null
          ? await _client.from('pos_terminals').select().order('name', ascending: true)
          : await _client
              .from('pos_terminals')
              .select()
              .eq('branch_id', branchId)
              .order('name', ascending: true);
      return rows
          .map((r) => PosTerminal.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> createTerminal({
    required String businessId,
    required String branchId,
    required String name,
  }) async {
    try {
      await _client.from('pos_terminals').insert({
        'business_id': businessId,
        'branch_id': branchId,
        'name': name.trim(),
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateTerminal({
    required String id,
    required String branchId,
    required String name,
    String status = 'active',
  }) async {
    try {
      await _client.from('pos_terminals').update({
        'branch_id': branchId,
        'name': name.trim(),
        'status': status,
      }).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
