import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/permissions_controller.dart';

/// Hides [child] unless the signed-in role holds [permission] (SPEC §3, §87).
///
/// Use it for individual buttons, fields and tiles — cost price, delete
/// actions, discounts — so the UI never offers an action the backend will
/// refuse. This is *cosmetic* protection only: Postgres (RLS +
/// `has_permission()`) is the real gate, proven by the pgTAP permission
/// matrix. When permissions are still loading the policy fails open (the
/// backend still refuses anything not granted), matching the shell's
/// behaviour. [fallback] replaces [child] when the permission is missing
/// (defaults to nothing).
class PermissionGate extends ConsumerWidget {
  /// Permission key (exact, e.g. `products.view_cost`) or `prefix.*`
  /// wildcard (e.g. `reports.*`).
  final String permission;

  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessPolicyProvider);
    if (access.grants(permission)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
