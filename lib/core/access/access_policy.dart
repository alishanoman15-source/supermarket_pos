/// UI-level access policy (SPEC §3 roles, §87 navigation).
///
/// Authorisation itself is enforced in Postgres (RLS + `has_permission()` RPC
/// guards, proven by the pgTAP `04_permission_matrix` suite). This class only
/// decides what a role is *offered* in the UI so the shell and the "More" hub
/// never advertise modules the backend will refuse (e.g. a cashier opening
/// profit reports or staff administration).
class AccessPolicy {
  /// Permission keys granted to the signed-in profile's role.
  final Set<String> permissions;

  /// Stable role template key (`owner`, `manager`, `cashier`, `stocker`,
  /// `viewer`, …) of the signed-in profile (SPEC §3 roles). Empty when the
  /// profile has no role — the UI then falls back to permission-based
  /// navigation.
  final String roleKey;

  /// True when permissions could not be resolved (offline, sign-in still
  /// loading, RPC failure). The UI then fails **open**: the backend still
  /// enforces every rule, so failing closed would only lock a legitimate user
  /// out of the app.
  final bool allowAll;

  const AccessPolicy(this.permissions, {this.roleKey = '', this.allowAll = false});

  const AccessPolicy.allowAll()
      : permissions = const {},
        roleKey = '',
        allowAll = true;

  /// Routes that must always stay reachable so no role is ever trapped
  /// (they are the escape hatches: profile, settings, sign-out, notifications).
  static const Set<String> alwaysAllowed = {
    '/app/more',
    '/app/profile',
    '/app/settings',
    '/app/notifications',
    '/app/search',
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/setup',
  };

  /// Candidate landing routes after sign-in, most desirable first. The first
  /// one the role may open becomes the post-login destination (a cashier lands
  /// on the POS, a stocker on inventory, an owner on the dashboard).
  static const List<String> landingCandidates = [
    '/app/dashboard',
    '/app/pos',
    '/app/inventory',
    '/app/more',
  ];

  /// Longest-prefix route rules. A location matches a key when it equals it or
  /// starts with `key + '/'`. Each entry lists acceptable permission tokens:
  /// either an exact permission key or a `prefix.*` wildcard.
  static const Map<String, List<String>> routePermissions = {
    // Admin / back office — hidden from cashiers and stockers (SPEC §3.4).
    '/app/businesses': ['platform.manage'], // Super Admin console (SPEC §3.1)
    '/app/team': ['users.manage'],
    '/app/audit': ['audit.view'],
    '/app/import-export': ['data.import', 'data.export'],
    '/app/promotions': ['promotions.manage'],
    '/app/expenses': ['expenses.manage'],
    '/app/branches': ['branches.manage'],
    '/app/terminals': ['branches.manage'],

    // Purchasing & suppliers — never visible to cashiers (SPEC §3.4).
    '/app/suppliers': ['purchases.view', 'suppliers.manage'],
    '/app/purchase-orders': ['purchases.view'],
    '/app/purchase-bills': ['purchases.view'],

    // Reports — one rule per report so roles can be granted selectively.
    '/app/reports/profit': ['reports.profit.view'],
    '/app/reports/expenses': ['expenses.manage'],
    '/app/reports/suppliers': ['purchases.view'],
    '/app/reports/customers': ['sales.view_all'],
    '/app/reports/products': ['reports.profit.view'],
    '/app/reports/cash': ['reports.cash.view', 'reports.shift.self'],
    '/app/reports/purchases': ['reports.purchases.view'],
    '/app/reports/inventory': ['reports.inventory.view'],
    '/app/reports/sales': ['reports.sales.view'],
    '/app/reports': ['reports.*'],
    '/app/dashboard': ['reports.dashboard.view'],

    // Read modules.
    '/app/products': ['products.view'],
    '/app/categories': ['products.view'],
    '/app/brands': ['products.view'],
    '/app/inventory': ['inventory.view'],
    '/app/customers': ['customers.manage'],
    '/app/sales': ['sales.view'],
    '/app/shifts': ['shifts.open', 'shifts.close', 'reports.shift.self'],

    // Mutating sub-routes inside otherwise visible modules.
    '/app/products/new': ['products.create'],
    '/app/categories/new': ['products.create'],
    '/app/brands/new': ['products.create'],
    '/app/inventory/adjust': ['inventory.adjust'],
    '/app/inventory/transfers': ['inventory.transfer'],
    '/app/inventory/counts': ['inventory.count'],
    '/app/purchase-orders/new': ['purchases.create'],
    '/app/suppliers/new': ['suppliers.manage'],
    '/app/customers/new': ['customers.manage'],
    '/app/expenses/new': ['expenses.manage'],
    '/app/promotions/new': ['promotions.manage'],

    // Offline sync queue — whoever may sell or read sales manages their queue.
    '/app/sync': ['pos.sell', 'sales.view'],

    // POS + full-screen sale flows.
    '/app/pos': ['pos.sell'],
    '/pos': ['pos.sell'],
    '/sales': ['sales.view'],
  };

  /// Ordered navigation per role template (SPEC §87): what each role is
  /// offered in the shell rail. Entries are still intersected with
  /// [canOpen], so a role never sees a module its permissions would refuse.
  /// Roles without an entry fall back to the full permission-filtered list.
  static const Map<String, List<String>> navByRole = {
    // Owner: full back office (SPEC §3.2).
    'owner': [
      '/app/dashboard',
      '/app/pos',
      '/app/sales',
      '/app/products',
      '/app/inventory',
      '/app/purchase-orders',
      '/app/customers',
      '/app/reports',
      '/app/shifts',
      '/app/more',
      '/app/settings',
    ],
    // Manager: same modules minus nothing, but staff admin stays in More and
    // owner-only configuration is never offered (SPEC §3.3).
    'manager': [
      '/app/dashboard',
      '/app/pos',
      '/app/products',
      '/app/inventory',
      '/app/purchase-orders',
      '/app/customers',
      '/app/reports',
      '/app/sales',
      '/app/shifts',
      '/app/more',
      '/app/settings',
    ],
    // Cashier: POS-first, no admin modules at all (SPEC §3.4, §87).
    'cashier': [
      '/app/pos',
      '/app/sales',
      '/app/customers',
      '/app/shifts',
      '/app/more',
      '/app/settings',
    ],
    // Inventory manager: catalogue, stock, receiving and stock reports
    // (SPEC §3.5).
    'stocker': [
      '/app/products',
      '/app/inventory',
      '/app/purchase-orders',
      '/app/reports',
      '/app/more',
      '/app/settings',
    ],
    // Read-only reporting role.
    'viewer': [
      '/app/dashboard',
      '/app/reports',
      '/app/products',
      '/app/inventory',
      '/app/sales',
      '/app/more',
      '/app/settings',
    ],
  };

  /// Ordered routes this role should be offered, or null when the role has no
  /// curated list (permission filtering applies to everything either way).
  List<String>? get navRoutes =>
      allowAll ? null : (roleKey.isEmpty ? null : navByRole[roleKey]);

  /// The navigation this role is actually offered: [candidates] (caller's
  /// canonical order) filtered by the curated per-role list (SPEC §87) and by
  /// [canOpen].
  ///
  /// Defensive: if a role's curated list is entirely denied by its own
  /// permissions (mis-seeded role), the pure permission filter is used instead
  /// so nobody is ever stranded without navigation.
  List<String> allowedRoutes(List<String> candidates) {
    final curated = navRoutes;
    bool allowed(String route) =>
        (curated == null || curated.contains(route)) && canOpen(route);

    final visible = [for (final r in candidates) if (allowed(r)) r];
    if (visible.isNotEmpty || curated == null) return visible;
    return [for (final r in candidates) if (canOpen(r)) r];
  }

  /// Whether a permission token is granted (exact key or `prefix.*` wildcard).
  bool _token(String token) {
    if (allowAll) return true;
    if (token.endsWith('.*')) {
      final prefix = token.substring(0, token.length - 1); // keep the dot
      return permissions.any((p) => p.startsWith(prefix));
    }
    return permissions.contains(token);
  }

  /// True when the current role holds [key].
  bool can(String key) => allowAll || permissions.contains(key);

  /// Whether a permission token is granted — accepts an exact key or a
  /// `prefix.*` wildcard. Used by [PermissionGate]-style UI checks so
  /// individual buttons and fields can be hidden for a role.
  bool grants(String token) => _token(token);

  /// Whether the role may open [location] (a matched route path).
  bool canOpen(String location) {
    if (allowAll) return true;
    if (alwaysAllowed.contains(location)) return true;

    String? bestKey;
    for (final key in routePermissions.keys) {
      if (location == key || location.startsWith('$key/')) {
        if (bestKey == null || key.length > bestKey.length) bestKey = key;
      }
    }
    if (bestKey == null) return true; // unmapped routes stay reachable
    return routePermissions[bestKey]!.any(_token);
  }

  /// First landing route this role may open; never null.
  String get firstAllowed {
    for (final route in landingCandidates) {
      if (canOpen(route)) return route;
    }
    return '/app/more';
  }

  /// Where to send a role that requested [denied]: a route it can open.
  String redirectFor(String denied) => firstAllowed;
}
