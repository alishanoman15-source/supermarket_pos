import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/access/access_policy.dart';
import '../../core/l10n/l10n.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/providers/permissions_controller.dart';

/// Adaptive app shell (SPEC §32, §88): bottom navigation under 600dp with the
/// five primary destinations plus a "More" hub, and a full navigation rail on
/// tablets/desktop.
class HomeShell extends ConsumerWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  static const double _railBreakpoint = 600;

  List<_Destination> _destinations(BuildContext context, AccessPolicy access) {
    final l10n = context.l10n;
    final all = <_Destination>[
      _Destination(Icons.dashboard_outlined, Icons.dashboard, l10n.dashboard,
          AppRoutes.dashboard),
      _Destination(Icons.point_of_sale_outlined, Icons.point_of_sale, l10n.pos, AppRoutes.pos),
      _Destination(Icons.receipt_long_outlined, Icons.receipt_long, l10n.sales,
          AppRoutes.sales),
      _Destination(Icons.inventory_2_outlined, Icons.inventory_2, l10n.products,
          AppRoutes.products),
      _Destination(Icons.warehouse_outlined, Icons.warehouse, l10n.inventory,
          AppRoutes.inventory),
      _Destination(Icons.local_shipping_outlined, Icons.local_shipping, l10n.purchases,
          AppRoutes.purchaseOrders),
      _Destination(Icons.people_outline, Icons.people, l10n.customers, AppRoutes.customers),
      _Destination(Icons.bar_chart_outlined, Icons.bar_chart, l10n.reports, AppRoutes.reports),
      _Destination(Icons.schedule_outlined, Icons.schedule, l10n.shifts, AppRoutes.shifts),
      _Destination(Icons.more_horiz, Icons.more_horiz, l10n.more, AppRoutes.more),
      _Destination(Icons.settings_outlined, Icons.settings, l10n.settings, AppRoutes.settings),
    ];

    // Role-based navigation (SPEC §3, §87): the curated per-role list first,
    // then the permission filter — so a cashier is offered exactly
    // POS / Sales / Customers / Shifts and never an admin module, while a
    // super admin (no curated list) keeps everything.
    final allowed = access.allowedRoutes(
      [for (final d in all) d.route],
    );
    final visible = [for (final d in all) if (allowed.contains(d.route)) d];

    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;
    if (wide) return visible;

    // Phones keep the four primary modules plus the "More" hub.
    final primary = visible.take(4).toList();
    final more = visible.firstWhere(
      (d) => d.route == AppRoutes.more,
      orElse: () => _Destination(
          Icons.more_horiz, Icons.more_horiz, l10n.more, AppRoutes.more),
    );
    return [...primary, more];
  }

  int _indexFor(List<_Destination> destinations, String location) {
    var bestIndex = 0;
    var bestLength = -1;
    for (var i = 0; i < destinations.length; i++) {
      final route = destinations[i].route;
      if (location.startsWith(route) && route.length > bestLength) {
        bestIndex = i;
        bestLength = route.length;
      }
    }
    return bestIndex;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final access = ref.watch(accessPolicyProvider);
    final destinations = _destinations(context, access);
    final index = _indexFor(destinations, location);
    final wide = MediaQuery.sizeOf(context).width >= _railBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            SingleChildScrollView(
              child: IntrinsicHeight(
                child: NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (i) => context.go(destinations[i].route),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selected),
                        label: Text(d.label),
                      ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(destinations[i].route),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selected),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selected;
  final String label;
  final String route;

  const _Destination(this.icon, this.selected, this.label, this.route);
}
