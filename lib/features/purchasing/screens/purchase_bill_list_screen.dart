import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/purchase.dart';
import '../providers/purchasing_providers.dart';

/// Purchase bills list (SPEC §42) with payment status and balance.
class PurchaseBillListScreen extends ConsumerWidget {
  const PurchaseBillListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.purchaseBills)),
      body: PagedListView<Purchase>(
        provider: purchasesControllerProvider,
        searchHint: l10n.billNumber,
        emptyMessage: l10n.noBills,
        emptyIcon: Icons.description_outlined,
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
                      ref.read(purchasesControllerProvider.notifier).setFilter('status', null),
                ),
                for (final status in const ['unpaid', 'partially_paid', 'paid'])
                  ChoiceChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: current == status,
                    onSelected: (_) =>
                        ref.read(purchasesControllerProvider.notifier).setFilter('status', status),
                  ),
              ],
            ),
          );
        },
        itemBuilder: (context, bill) => ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(bill.billNumber ?? '—'),
          subtitle: Text([
            bill.supplierName,
            fmt.format(bill.receivedAt),
            if (bill.dueAt != null) '${l10n.dueDate}: ${fmt.format(bill.dueAt!)}',
          ].join(' · ')),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(bill.balance), style: Theme.of(context).textTheme.labelLarge),
              StatusChip(status: bill.status),
            ],
          ),
        ),
      ),
    );
  }
}
