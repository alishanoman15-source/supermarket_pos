import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_codes.dart';
import '../models/team.dart';

/// Staff profiles, roles and the permission catalogue (SPEC §66, §67).
class TeamRepository {
  final SupabaseClient _client;

  const TeamRepository(this._client);

  /// Invites a new employee through the `staff-invite` edge function
  /// (SPEC §83) — creating an auth user needs the service-role key, which
  /// must never ship inside Flutter (SPEC §56).
  Future<void> inviteMember({
    required String email,
    required String name,
    required String roleId,
    String? roleKey,
    String? branchId,
    String? phone,
  }) async {
    try {
      final res = await _client.functions.invoke('staff-invite', body: {
        'email': email,
        'name': name,
        'role_id': roleId,
        'role_key': roleKey,
        'branch_id': branchId,
        'phone': phone,
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) return;
      final error = data is Map
          ? Map<String, dynamic>.from(data['error'] as Map? ?? const {})
          : const <String, dynamic>{};
      throw AppException(
        (error['code'] as String?) ?? ErrorCode.internalError,
        (error['message'] as String?) ?? ErrorMessages.describe(data),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<TeamMember>> fetchTeam() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('*, role:roles(name)')
          .order('name', ascending: true);
      return rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        final role = map['role'];
        if (role is Map) map['role_name'] = role['name'];
        return TeamMember.fromMap(map);
      }).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<AppRole>> fetchRoles() async {
    try {
      final rows = await _client.from('roles').select().order('name', ascending: true);
      return rows.map((r) => AppRole.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<AppPermission>> fetchPermissions() async {
    try {
      final rows = await _client.from('permissions').select().order('category', ascending: true).order('key', ascending: true);
      return rows.map((r) => AppPermission.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Stable template key of a role (`owner`, `cashier`, …) or `''` when the
  /// role is custom / unknown. Drives the per-role navigation (SPEC §87).
  Future<String> fetchRoleKey(String roleId) async {
    try {
      final row =
          await _client.from('roles').select('key').eq('id', roleId).maybeSingle();
      return (row?['key'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Permission keys currently granted to a role.
  Future<Set<String>> fetchRolePermissionKeys(String roleId) async {
    try {
      final rows = await _client
          .from('role_permissions')
          .select('permissions(key)')
          .eq('role_id', roleId);
      final keys = <String>{};
      for (final r in rows) {
        final permission = (r as Map)['permissions'];
        if (permission is Map && permission['key'] is String) {
          keys.add(permission['key'] as String);
        }
      }
      return keys;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Whether [roleId] is the system `owner` template role (SPEC §67).
  Future<bool> _isOwnerSystemRole(String roleId) async {
    final row = await _client
        .from('roles')
        .select('key,is_system')
        .eq('id', roleId)
        .maybeSingle();
    return row != null &&
        row['key'] == 'owner' &&
        row['is_system'] == true;
  }

  /// Creates or updates a role and replaces its permission grants.
  Future<void> saveRole({
    String? id,
    required String businessId,
    required String name,
    String? description,
    required Set<String> permissionKeys,
  }) async {
    try {
      String roleId = id ?? '';
      if (id == null) {
        final inserted = await _client
            .from('roles')
            .insert({'business_id': businessId, 'name': name.trim(), 'description': description})
            .select('id')
            .single();
        roleId = inserted['id'] as String;
      } else {
        await _client
            .from('roles')
            .update({'name': name.trim(), 'description': description}).eq('id', id);
        roleId = id;
      }

      // The system `owner` role is the business owner's own role: saving it
      // with an empty (or partial) selection would strip the account's access
      // to every module and collapse the shell navigation (SPEC §67, §87).
      // Force the full catalogue so that can never happen from the UI.
      if (await _isOwnerSystemRole(roleId)) {
        final all = await _client.from('permissions').select('key');
        permissionKeys = {
          for (final p in all)
            if (p['key'] is String) p['key'] as String,
        };
      }

      await _client.from('role_permissions').delete().eq('role_id', roleId);
      if (permissionKeys.isEmpty) return;

      final perms = await _client.from('permissions').select('id,key').inFilter('key', permissionKeys.toList());
      final rows = perms
          .where((p) => permissionKeys.contains(p['key']))
          .map((p) => {'role_id': roleId, 'permission_id': p['id']})
          .toList();
      if (rows.isNotEmpty) {
        await _client.from('role_permissions').insert(rows);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      await _client.from('roles').delete().eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> assignRole({required String profileId, required String roleId}) async {
    try {
      await _client.from('profiles').update({'role_id': roleId}).eq('id', profileId);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Sets a new password for a team member's auth account (SPEC §66).
  ///
  /// Invited staff sometimes lose the password they set while accepting the
  /// invite, and email reset links only work once SMTP/redirects are
  /// configured — so the owner can reset it directly from the Team screen.
  /// The password is never logged or stored anywhere but Supabase Auth.
  Future<void> resetMemberPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final res = await _client.functions.invoke('staff-password-reset', body: {
        'user_id': userId,
        'password': password,
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) return;
      final error = data is Map
          ? Map<String, dynamic>.from(data['error'] as Map? ?? const {})
          : const <String, dynamic>{};
      throw AppException(
        (error['code'] as String?) ?? ErrorCode.internalError,
        (error['message'] as String?) ?? ErrorMessages.describe(data),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateMember({
    required String profileId,
    String? name,
    String? phone,
    String? status,
  }) async {
    try {
      await _client.from('profiles').update({
        'name': ?name,
        'phone': ?phone,
        'status': ?status,
      }).eq('id', profileId);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
