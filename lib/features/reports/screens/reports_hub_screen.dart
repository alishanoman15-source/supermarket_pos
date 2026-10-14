import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/permissions_controller.dart';

/// Reports hub (SPEC §59): entry point for every aggregated report. Reports
/// the signed-in role may not open are hidden (product spec §3.4 — a cashier
/// never sees cost, profit or finance reports).
class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final entries = <_ReportEntry>[
      _ReportEntry(
        icon: Icons.receipt_long_outlined,
        title: l10n.salesReport,
        subtitle: l10n.grossSales,
        route: AppRoutes.reportSales,
        color: Colors.teal,
      ),
      _ReportEntry(
        icon: Icons.trending_up,
        title: l10n.profitReport,
        subtitle: l10n.grossProfit,
        route: AppRoutes.reportProfit,
        color: Colors.green,
      ),
      _ReportEntry(
        icon: Icons.warehouse_outlined,
        title: l10n.inventoryReport,
        subtitle: l10n.valueAtCost,
        route: AppRoutes.reportInventory,
        color: Colors.indigo,
      ),
      _ReportEntry(
        icon: Icons.local_shipping_outlined,
        title: l10n.purchasesReport,
        subtitle: l10n.purchases,
        route: AppRoutes.reportPurchases,
        color: Colors.orange,
      ),
      _ReportEntry(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.cashReport,
        subtitle: l10n.shifts,
        route: AppRoutes.reportCash,
        color: Colors.blueGrey,
      ),
      _ReportEntry(
        icon: Icons.calculate_outlined,
        title: l10n.costingReport,
        subtitle: l10n.marginPct,
        route: AppRoutes.reportCosting,
        color: Colors.purple,
      ),
      _ReportEntry(
        icon: Icons.receipt_long_outlined,
        title: l10n.expensesReport,
        subtitle: l10n.expensesTotal,
        route: AppRoutes.reportExpenses,
        color: Colors.deepOrange,
      ),
      _ReportEntry(
        icon: Icons.local_shipping_outlined,
        title: l10n.suppliersReport,
        subtitle: l10n.balanceDue,
        route: AppRoutes.reportSuppliers,
        color: Colors.cyan.shade700,
      ),
      _ReportEntry(
        icon: Icons.people_outline,
        title: l10n.customersReport,
        subtitle: l10n.revenue,
        route: AppRoutes.reportCustomers,
        color: Colors.teal.shade700,
      ),
      _ReportEntry(
        icon: Icons.inventory_2_outlined,
        title: l10n.productsReport,
        subtitle: l10n.unitsSold,
        route: AppRoutes.reportProducts,
        color: Colors.blueGrey.shade700,
      ),
    ];

    final access = ref.watch(accessPolicyProvider);
    final visible = [
      for (final entry in entries)
        if (access.canOpen(entry.route)) entry,
    ];

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsHub)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.reportsSubtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              for (final entry in visible)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(entry.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: entry.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(entry.icon, color: entry.color),
                          ),
                          const Spacer(),
                          Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            entry.subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportEntry {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color color;

  const _ReportEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.color,
  });
}
