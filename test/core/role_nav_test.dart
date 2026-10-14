import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/access/access_policy.dart';

/// Candidate order mirrors the shell rail in `home_shell.dart`.
const _candidates = [
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
];

/// Grant sets mirror `create_business_with_owner` (SPEC §67 role templates).
Set<String> _ownerPerms() => {
      'reports.dashboard.view',
      'pos.sell',
      'products.view',
      'inventory.view',
      'purchases.view',
      'customers.manage',
      'sales.view',
      'shifts.open',
      'reports.sales.view',
      'users.manage',
      'settings.manage',
    };

Set<String> _managerPerms() => {
      'reports.dashboard.view',
      'pos.sell',
      'products.view',
      'inventory.view',
      'purchases.view',
      'customers.manage',
      'sales.view',
      'shifts.open',
      'reports.sales.view',
    };

Set<String> _cashierPerms() => {
      'pos.sell',
      'pos.hold',
      'products.view',
      'inventory.view',
      'sales.view',
      'customers.manage',
      'shifts.open',
      'shifts.close',
      'cash.move',
      'reports.shift.self',
      'notifications.view',
    };

Set<String> _stockerPerms() => {
      'products.view',
      'inventory.view',
      'inventory.adjust',
      'inventory.count',
      'inventory.transfer',
      'notifications.view',
      'purchases.view',
      'purchases.receive',
      'reports.inventory.view',
    };

Set<String> _viewerPerms() => {
      'products.view',
      'inventory.view',
      'sales.view',
      'sales.view_all',
      'reports.dashboard.view',
      'reports.sales.view',
      'reports.profit.view',
      'reports.inventory.view',
      'reports.purchases.view',
      'reports.cash.view',
    };

void main() {
  group('Role-based navigation (SPEC §3, §87)', () {
    test('owner gets the full back office and lands on the dashboard', () {
      final policy = AccessPolicy(_ownerPerms(), roleKey: 'owner');
      expect(policy.firstAllowed, '/app/dashboard');
      expect(policy.allowedRoutes(_candidates), [
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
      ]);
    });

    test('manager sees every module incl. sales history', () {
      final policy = AccessPolicy(_managerPerms(), roleKey: 'manager');
      expect(policy.firstAllowed, '/app/dashboard');
      final nav = policy.allowedRoutes(_candidates);
      expect(nav, contains('/app/sales'));
      expect(nav, contains('/app/purchase-orders'));
      expect(nav, isNot(contains('/app/team')));
    });

    test('cashier is offered POS / Sales / Customers / Shifts only', () {
      final policy = AccessPolicy(_cashierPerms(), roleKey: 'cashier');
      // A cashier never lands on the admin dashboard.
      expect(policy.firstAllowed, '/app/pos');
      expect(policy.allowedRoutes(_candidates), [
        '/app/pos',
        '/app/sales',
        '/app/customers',
        '/app/shifts',
        '/app/more',
        '/app/settings',
      ]);
      // Even though products.view/inventory.view are granted (POS lookup),
      // the curated list keeps catalogue and stock out of the rail.
      expect(policy.canOpen('/app/products'), isTrue);
      expect(policy.allowedRoutes(_candidates), isNot(contains('/app/products')));
      expect(policy.allowedRoutes(_candidates), isNot(contains('/app/inventory')));
      expect(policy.allowedRoutes(_candidates), isNot(contains('/app/dashboard')));
    });

    test('inventory manager (stocker) gets stock, receiving and stock reports',
        () {
      final policy = AccessPolicy(_stockerPerms(), roleKey: 'stocker');
      expect(policy.firstAllowed, '/app/inventory');
      expect(policy.allowedRoutes(_candidates), [
        '/app/products',
        '/app/inventory',
        '/app/purchase-orders',
        '/app/reports',
        '/app/more',
        '/app/settings',
      ]);
      // No POS, no customer list, no sales dashboard.
      expect(policy.allowedRoutes(_candidates), isNot(contains('/app/pos')));
      expect(policy.allowedRoutes(_candidates), isNot(contains('/app/dashboard')));
    });

    test('viewer is read-only: dashboard + reports, no POS', () {
      final policy = AccessPolicy(_viewerPerms(), roleKey: 'viewer');
      expect(policy.firstAllowed, '/app/dashboard');
      final nav = policy.allowedRoutes(_candidates);
      expect(nav, contains('/app/reports'));
      expect(nav, isNot(contains('/app/pos')));
      expect(nav, isNot(contains('/app/purchase-orders')));
    });

    test('a custom role (no template key) falls back to permissions', () {
      final policy = AccessPolicy(_cashierPerms());
      expect(policy.navRoutes, isNull);
      final nav = policy.allowedRoutes(_candidates);
      expect(nav, contains('/app/pos'));
      expect(nav, contains('/app/products')); // allowed by products.view
      expect(nav, contains('/app/sales')); // allowed by sales.view
      expect(nav, isNot(contains('/app/purchase-orders'))); // needs purchases.view
      expect(nav, isNot(contains('/app/dashboard'))); // needs reports.dashboard.view
    });

    test('a curated list that permissions fully deny falls back safely', () {
      // Curated list says "POS only" but the role holds dashboard instead:
      // navigation must still offer something instead of nothing.
      final policy = AccessPolicy(
        {'reports.dashboard.view'},
        roleKey: 'cashier',
      );
      expect(policy.allowedRoutes(['/app/pos', '/app/dashboard']), [
        '/app/dashboard',
      ]);
    });

    test('super admin (allow-all) sees every candidate', () {
      const policy = AccessPolicy.allowAll();
      expect(policy.navRoutes, isNull);
      expect(policy.allowedRoutes(_candidates), _candidates);
    });
  });
}
