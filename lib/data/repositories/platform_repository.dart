import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../core/errors/app_exception.dart';

/// One business row from `admin_list_businesses()` (SPEC §3.1).
class AdminBusiness {
  final String id;
  final String name;
  final String? currency;
  final String status;
  final int branchCount;
  final int staffCount;
  final int productCount;

  const AdminBusiness({
    required this.id,
    required this.name,
    required this.status,
    this.currency,
    this.branchCount = 0,
    this.staffCount = 0,
    this.productCount = 0,
  });

  factory AdminBusiness.fromMap(Map<String, dynamic> map) => AdminBusiness(
        id: map['id'] as String,
        name: (map['name'] as String?) ?? '',
        currency: map['currency'] as String?,
        status: (map['status'] as String?) ?? 'active',
        branchCount: (map['branch_count'] as num?)?.toInt() ?? 0,
        staffCount: (map['staff_count'] as num?)?.toInt() ?? 0,
        productCount: (map['product_count'] as num?)?.toInt() ?? 0,
      );
}

/// Super Admin (SPEC §3.1) platform operations. Every call goes through a
/// backend RPC guarded by `is_super_admin()` — the UI gate is presentation
/// only, the server is the authority.
class PlatformRepository {
  final SupabaseClient _client;

  const PlatformRepository(this._client);

  /// Whether the signed-in user is a platform super admin. RLS lets a user
  /// read their own membership row only.
  Future<bool> isSuperAdmin() async {
    try {
      final rows = await _client
          .from('super_admins')
          .select('user_id')
          .eq('user_id', _client.auth.currentUser?.id ?? '')
          .limit(1);
      return rows.isNotEmpty;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Every business on the platform with headline counts.
  Future<List<AdminBusiness>> listBusinesses() async {
    try {
      final rows = await _client.rpc('admin_list_businesses');
      return (rows as List)
          .map((r) => AdminBusiness.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Branches of any business (RLS: super admins see every branch).
  Future<List<Map<String, dynamic>>> listBranches(String businessId) async {
    try {
      final rows = await _client
          .from('branches')
          .select()
          .eq('business_id', businessId)
          .order('name');
      return rows.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> createBranch({
    required String businessId,
    required String name,
    String? address,
    String? phone,
  }) async {
    try {
      await _client.rpc('admin_create_branch', params: {
        'p_business': businessId,
        'p_name': name,
        'p_address': address,
        'p_phone': phone,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> grantSuperAdmin(String email) async {
    try {
      await _client.rpc('grant_super_admin', params: {'p_email': email});
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> revokeSuperAdmin(String email) async {
    try {
      await _client.rpc('revoke_super_admin', params: {'p_email': email});
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
