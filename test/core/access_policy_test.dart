import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/access/access_policy.dart';

void main() {
  // Mirrors the cashier template from docs/PERMISSIONS.md.
  const cashier = AccessPolicy({
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
  });

  // Owner holds every permission key.
  const owner = AccessPolicy({
    'business.manage',
    'branches.manage',
    'users.manage',
    'roles.manage',
    'products.view',
    'products.create',
    'products.view_cost',
    'inventory.view',
    'inventory.adjust',
    'purchases.view',
    'suppliers.manage',
    'pos.sell',
    'sales.view',
    'sales.view_all',
    'reports.dashboard.view',
    'reports.profit.view',
    'reports.cash.view',
    'reports.sales.view',
    'expenses.manage',
    'promotions.manage',
    'audit.view',
    'data.import',
    'data.export',
    'customers.manage',
    'shifts.open',
  });

  group('AccessPolicy — cashier (SPEC §3.4)', () {
    test('may open POS, sales, customers, inventory and its own shift report',
        () {
      expect(cashier.canOpen('/app/pos'), isTrue);
      expect(cashier.canOpen('/pos/payment'), isTrue);
      expect(cashier.canOpen('/app/sales'), isTrue);
      expect(cashier.canOpen('/app/customers'), isTrue);
      expect(cashier.canOpen('/app/inventory'), isTrue);
      expect(cashier.canOpen('/app/shifts'), isTrue);
      expect(cashier.canOpen('/app/reports/cash'), isTrue); // reports.shift.self
    });

    test('cannot open admin, financial or purchasing modules', () {
      expect(cashier.canOpen('/app/team'), isFalse);
      expect(cashier.canOpen('/app/audit'), isFalse);
      expect(cashier.canOpen('/app/import-export'), isFalse);
      expect(cashier.canOpen('/app/promotions'), isFalse);
      expect(cashier.canOpen('/app/expenses'), isFalse);
      expect(cashier.canOpen('/app/suppliers'), isFalse);
      expect(cashier.canOpen('/app/purchase-orders'), isFalse);
      expect(cashier.canOpen('/app/reports/profit'), isFalse);
      expect(cashier.canOpen('/app/reports/sales'), isFalse);
      expect(cashier.canOpen('/app/dashboard'), isFalse); // no dashboard KPIs
    });

    test('cannot create products or adjust stock', () {
      expect(cashier.canOpen('/app/products'), isTrue);
      expect(cashier.canOpen('/app/products/new'), isFalse);
      expect(cashier.canOpen('/app/products/view/abc'), isTrue);
      expect(cashier.canOpen('/app/inventory/adjust/p1'), isFalse);
      expect(cashier.canOpen('/app/inventory/transfers'), isFalse);
    });

    test('escape hatches always stay reachable', () {
      for (final route in AccessPolicy.alwaysAllowed) {
        expect(cashier.canOpen(route), isTrue, reason: route);
      }
      expect(cashier.canOpen('/app/more'), isTrue);
      expect(cashier.canOpen('/app/settings'), isTrue);
      expect(cashier.canOpen('/app/profile'), isTrue);
    });

    test('lands on the POS, not the dashboard (SPEC §87)', () {
      expect(cashier.firstAllowed, '/app/pos');
    });
  });

  group('AccessPolicy — owner', () {
    test('may open every mapped route', () {
      expect(owner.canOpen('/app/team'), isTrue);
      expect(owner.canOpen('/app/dashboard'), isTrue);
      expect(owner.canOpen('/app/reports/profit'), isTrue);
      expect(owner.canOpen('/app/suppliers'), isTrue);
      expect(owner.canOpen('/app/products/new'), isTrue);
      expect(owner.firstAllowed, '/app/dashboard');
    });
  });

  // Mirrors the manager template in create_business_with_owner: every
  // permission except roles.manage (role *administration* is owner-only).
  const manager = AccessPolicy({
    'business.manage',
    'branches.manage',
    'branches.access_all',
    'users.manage',
    'products.view',
    'products.create',
    'products.update',
    'products.deactivate',
    'products.view_cost',
    'pricing.override',
    'pricing.discount',
    'pricing.discount_cart',
    'inventory.view',
    'inventory.adjust',
    'inventory.transfer',
    'inventory.count',
    'inventory.count_approve',
    'purchases.view',
    'purchases.create',
    'purchases.approve',
    'purchases.receive',
    'suppliers.manage',
    'suppliers.pay',
    'pos.sell',
    'pos.hold',
    'pos.sell_offline',
    'sales.view',
    'sales.view_all',
    'sales.cancel',
    'returns.process',
    'refund.large',
    'customers.manage',
    'loyalty.manage',
    'expenses.manage',
    'shifts.open',
    'shifts.close',
    'cash.move',
    'reports.dashboard.view',
    'reports.sales.view',
    'reports.profit.view',
    'reports.inventory.view',
    'reports.purchases.view',
    'reports.cash.view',
    'reports.shift.self',
    'promotions.manage',
    'notifications.view',
    'audit.view',
    'settings.manage',
    'data.import',
    'data.export',
  });

  // Mirrors the stocker (inventory manager) template.
  const stocker = AccessPolicy({
    'products.view',
    'inventory.view',
    'inventory.adjust',
    'inventory.count',
    'inventory.transfer',
    'notifications.view',
  });

  group('AccessPolicy — manager', () {
    test('runs the whole store except role administration', () {
      expect(manager.canOpen('/app/dashboard'), isTrue);
      expect(manager.canOpen('/app/team'), isTrue); // users.manage
      expect(manager.canOpen('/app/reports/profit'), isTrue);
      expect(manager.canOpen('/app/suppliers'), isTrue);
      expect(manager.canOpen('/app/purchase-orders'), isTrue);
      expect(manager.canOpen('/app/products/new'), isTrue);
      expect(manager.canOpen('/app/expenses'), isTrue);
      expect(manager.canOpen('/app/audit'), isTrue);
      expect(manager.canOpen('/app/import-export'), isTrue);
      expect(manager.canOpen('/app/promotions'), isTrue);
      expect(manager.firstAllowed, '/app/dashboard');
    });

    test('cannot reach the cross-business platform console', () {
      // platform.manage is a super-admin capability, granted to no
      // business role — not even the owner.
      expect(manager.can('/app/businesses') || manager.canOpen('/app/businesses'),
          isFalse);
    });
  });

  group('AccessPolicy — stocker (inventory manager)', () {
    test('may run inventory operations and read the catalogue', () {
      expect(stocker.canOpen('/app/inventory'), isTrue);
      expect(stocker.canOpen('/app/products'), isTrue);
      expect(stocker.canOpen('/app/inventory/transfers'), isTrue);
      expect(stocker.canOpen('/app/inventory/counts'), isTrue);
      expect(stocker.canOpen('/app/inventory/adjust/p1'), isTrue);
      expect(stocker.canOpen('/app/inventory/batches'), isTrue);
    });

    test('may not sell, buy or see financial modules', () {
      expect(stocker.canOpen('/app/pos'), isFalse);
      expect(stocker.canOpen('/app/reports'), isFalse);
      expect(stocker.canOpen('/app/reports/profit'), isFalse);
      expect(stocker.canOpen('/app/team'), isFalse);
      expect(stocker.canOpen('/app/suppliers'), isFalse);
      expect(stocker.canOpen('/app/purchase-orders'), isFalse);
      expect(stocker.canOpen('/app/expenses'), isFalse);
    });

    test('lands on inventory (SPEC §87)', () {
      expect(stocker.firstAllowed, '/app/inventory');
    });
  });

  group('AccessPolicy — grants() for PermissionGate', () {
    test('matches exact keys and prefix wildcards', () {
      expect(cashier.grants('pos.sell'), isTrue);
      expect(cashier.grants('products.view_cost'), isFalse);
      // The cashier template includes reports.shift.self, so the wildcard
      // matches — but a single specific report key does not.
      expect(cashier.grants('reports.*'), isTrue);
      expect(cashier.grants('reports.profit.view'), isFalse);
      expect(const AccessPolicy({'products.view'}).grants('reports.*'), isFalse);
      expect(manager.grants('reports.*'), isTrue);
      expect(manager.grants('products.view_cost'), isTrue);
      expect(const AccessPolicy.allowAll().grants('anything.at_all'), isTrue);
    });
  });

  group('AccessPolicy — wildcards and fail-open', () {
    test('reports.* matches any report permission', () {
      const viewer = AccessPolicy({'reports.sales.view'});
      expect(viewer.canOpen('/app/reports'), isTrue);
      expect(viewer.canOpen('/app/reports/sales'), isTrue);
      expect(viewer.canOpen('/app/reports/profit'), isFalse);
    });

    test('allow-all policy opens everything (offline / unknown role)', () {
      const open = AccessPolicy.allowAll();
      expect(open.canOpen('/app/team'), isTrue);
      expect(open.canOpen('/app/reports/profit'), isTrue);
      expect(open.firstAllowed, '/app/dashboard');
    });

    test('unmapped routes stay reachable so no module becomes a dead link', () {
      expect(cashier.canOpen('/app/anything-new'), isTrue);
    });
  });
}
