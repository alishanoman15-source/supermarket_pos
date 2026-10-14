import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/purchase.dart';
import '../providers/purchasing_providers.dart';

/// Purchase order list (SPEC §36) with status filter and pagination.
class PurchaseOrderListScreen extends ConsumerWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.purchaseOrders)),
      body: PagedListView<PurchaseOrder>(
        provider: purchaseOrdersControllerProvider,
        searchHint: l10n.poNumber,
        emptyMessage: l10n.noPurchaseOrders,
        emptyIcon: Icons.receipt_long_outlined,
        emptyActionLabel: l10n.newPurchaseOrder,
        onEmptyAction: () => context.push(AppRoutes.purchaseOrderNew),
        filterBar: (context, ref, state) {
          final current = state.filters['status'] ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.statusAll),
                  selected: current.isEmpty,
                  onSelected: (_) =>
                      ref.read(purchaseOrdersControllerProvider.notifier).setFilter('status', null),
                ),
                for (final status in const ['draft', 'approved', 'partially_received', 'received'])
                  ChoiceChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: current == status,
                    onSelected: (_) => ref
                        .read(purchaseOrdersControllerProvider.notifier)
                        .setFilter('status', status),
                  ),
              ],
            ),
          );
        },
        itemBuilder: (context, order) => ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: Text(order.poNumber ?? '—'),
          subtitle: Text([
            order.supplierName,
            if (order.expectedAt != null) fmt.format(order.expectedAt!),
          ].join(' · ')),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(order.total), style: Theme.of(context).textTheme.labelLarge),
              StatusChip(status: order.status),
            ],
          ),
          onTap: () => context.push('${AppRoutes.purchaseOrders}/${order.id}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.purchaseOrderNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.newPurchaseOrder),
      ),
    );
  }
}
