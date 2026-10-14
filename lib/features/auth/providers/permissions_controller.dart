import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/access/access_policy.dart';
import '../../../data/providers.dart';
import 'session_controller.dart';

/// Resolves the permission keys granted to the signed-in profile's role and
/// exposes them as an [AccessPolicy] for the shell, the "More" hub and the
/// router redirect (SPEC §3, §87).
///
/// Security itself lives in Postgres (`has_permission()`, RLS, RPC guards);
/// this is presentation only. When the keys cannot be resolved the policy fails
/// open (every route allowed) so a transient error never locks a legitimate
/// user out — the backend still refuses anything the role may not do.
class PermissionsController extends AsyncNotifier<AccessPolicy> {
  @override
  Future<AccessPolicy> build() async {
    final session = ref.watch(sessionControllerProvider);
    // Platform super admins (SPEC §3.1) hold every capability in the UI; the
    // server re-checks `is_super_admin()` on every sensitive call.
    if (session.isSuperAdmin) return const AccessPolicy.allowAll();
    final roleId = session.profile?.roleId;
    if (roleId == null) return const AccessPolicy.allowAll();

    try {
      final team = ref.read(teamRepositoryProvider);
      final keys = await team.fetchRolePermissionKeys(roleId);
      // The role template key drives the curated per-role navigation
      // (SPEC §87) — a cashier is offered POS/Sales/Customers/Shifts, never
      // the back office.
      final roleKey = await team.fetchRoleKey(roleId);
      return AccessPolicy(keys, roleKey: roleKey);
    } catch (_) {
      // Offline / RPC failure: fail open on the UI, stay strict on the server.
      return const AccessPolicy.allowAll();
    }
  }
}

final permissionsProvider =
    AsyncNotifierProvider<PermissionsController, AccessPolicy>(
  PermissionsController.new,
);

/// Synchronous view of the policy for builders that cannot await: resolves to
/// allow-all until the real keys arrive.
final accessPolicyProvider = Provider<AccessPolicy>((ref) {
  return ref.watch(permissionsProvider).valueOrNull ?? const AccessPolicy.allowAll();
});
