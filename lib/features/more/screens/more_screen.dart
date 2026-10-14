import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/permissions_controller.dart';

/// "More" hub (SPEC §32). Exposes every module that does not fit the primary
/// navigation so all screens stay reachable on phones.
///
/// Entries the signed-in role may not open are hidden (SPEC §3, §87).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final access = ref.watch(accessPolicyProvider);
    final groups = <_Group>[
      _Group(title: l10n.purchases, items: [
        _Item(Icons.local_shipping_outlined, l10n.suppliers, AppRoutes.suppliers),
        _Item(Icons.receipt_long_outlined, l10n.purchaseOrders, AppRoutes.purchaseOrders),
        _Item(Icons.description_outlined, l10n.purchaseBills, AppRoutes.purchaseBills),
      ]),
      _Group(title: l10n.customers, items: [
        _Item(Icons.people_outline, l10n.customers, AppRoutes.customers),
        _Item(Icons.local_offer_outlined, l10n.promotions, AppRoutes.promotions),
      ]),
      _Group(title: l10n.inventory, items: [
        _Item(Icons.event_note_outlined, l10n.batches, AppRoutes.batches),
        _Item(Icons.fact_check_outlined, l10n.stockCounts, AppRoutes.stockCounts),
        _Item(Icons.swap_horiz, l10n.stockTransfers, AppRoutes.stockTransfers),
      ]),
      _Group(title: l10n.expenses, items: [
        _Item(Icons.payments_outlined, l10n.expenses, AppRoutes.expenses),
        _Item(Icons.category_outlined, l10n.expenseCategories, AppRoutes.expenseCategories),
      ]),
      _Group(title: l10n.reports, items: [
        _Item(Icons.bar_chart_outlined, l10n.reportsHub, AppRoutes.reports),
        _Item(Icons.schedule_outlined, l10n.shifts, AppRoutes.shifts),
      ]),
      _Group(title: l10n.settings, items: [
        _Item(Icons.apartment_outlined, l10n.businesses, AppRoutes.businesses),
        _Item(Icons.store_mall_directory_outlined, l10n.branches, AppRoutes.branches),
        _Item(Icons.badge_outlined, l10n.team, AppRoutes.team),
        _Item(Icons.history_outlined, l10n.auditLog, AppRoutes.audit),
        _Item(Icons.import_export_outlined, l10n.importExport, AppRoutes.importExport),
        _Item(Icons.notifications_outlined, l10n.notifications, AppRoutes.notifications),
        _Item(Icons.sync_outlined, l10n.syncStatus, AppRoutes.syncStatus),
        _Item(Icons.search, l10n.globalSearch, AppRoutes.search),
        _Item(Icons.person_outline, l10n.myProfile, AppRoutes.profile),
        _Item(Icons.settings_outlined, l10n.settings, AppRoutes.settings),
      ]),
    ];

    final visible = [
      for (final group in groups)
        if (group.items.any((i) => access.canOpen(i.route)))
          _Group(
            title: group.title,
            items: [
              for (final item in group.items)
                if (access.canOpen(item.route)) item,
            ],
          ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.more)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final group in visible) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(group.title, style: Theme.of(context).textTheme.titleSmall),
            ),
            Card(
              child: Column(
                children: [
                  for (final item in group.items)
                    ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(item.route),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Group {
  final String title;
  final List<_Item> items;

  const _Group({required this.title, required this.items});
}

class _Item {
  final IconData icon;
  final String label;
  final String route;

  const _Item(this.icon, this.label, this.route);
}
