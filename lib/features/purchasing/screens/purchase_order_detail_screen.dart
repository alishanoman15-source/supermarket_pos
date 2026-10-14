import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/purchase.dart';
import '../../../data/providers.dart';
import '../providers/purchasing_providers.dart';

/// Purchase order detail (SPEC §37/§38): review lines, approve, then receive.
class PurchaseOrderDetailScreen extends ConsumerWidget {
  final String purchaseOrderId;

  const PurchaseOrderDetailScreen({super.key, required this.purchaseOrderId});

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.approveOrder,
      message: l10n.approveOrder,
      confirmLabel: l10n.approve,
    );
    if (!ok) return;
    try {
      await ref.read(purchasingRepositoryProvider).approvePurchaseOrder(purchaseOrderId);
      ref.invalidate(purchaseOrderProvider(purchaseOrderId));
      ref.invalidate(purchaseOrdersControllerProvider);
      if (context.mounted) showSnack(context, l10n.orderApprovedMsg);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final order = ref.watch(purchaseOrderProvider(purchaseOrderId));
    final items = ref.watch(purchaseOrderItemsProvider(purchaseOrderId));
    final fmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: Text(order.valueOrNull?.poNumber ?? l10n.purchaseOrder),
        actions: [
          if (order.valueOrNull?.isDraft == true)
            IconButton(
              tooltip: l10n.approveOrder,
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _approve(context, ref),
            ),
          if (order.valueOrNull?.canReceive == true)
            IconButton(
              tooltip: l10n.receiveGoods,
              icon: const Icon(Icons.inventory_outlined),
              onPressed: () =>
                  context.push('${AppRoutes.purchaseOrders}/$purchaseOrderId/receive'),
            ),
        ],
      ),
      body: AsyncView<PurchaseOrder?>(
        value: order,
        onRetry: () => ref.invalidate(purchaseOrderProvider(purchaseOrderId)),
        builder: (data) {
          if (data == null) return Center(child: Text(l10n.productNotFound));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: data.supplierName,
                trailing: StatusChip(status: data.status),
                child: Column(
                  children: [
                    if (data.expectedAt != null)
                      DetailRow(label: l10n.expectedDate, value: fmt.format(data.expectedAt!)),
                    DetailRow(label: l10n.subtotal, value: money(data.subtotal)),
                    DetailRow(label: l10n.tax, value: money(data.taxTotal)),
                    DetailRow(label: l10n.total, value: money(data.total), emphasize: true),
                    if (data.note?.isNotEmpty == true)
                      DetailRow(label: l10n.note, value: data.note!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              items.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (e, _) => Text(e is AppException ? e.message : l10n.somethingWentWrong),
                data: (lines) => SectionCard(
                  title: l10n.orderLines,
                  child: Column(
                    children: [
                      for (final line in lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(line.productName)),
                                  Text(money(line.lineTotal)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l10n.orderedQty} ${formatQty(line.qty)} · '
                                      '${l10n.receivedQty} ${formatQty(line.receivedQty)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ),
                                  Text('@ ${money(line.unitCost)}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(value: line.progress, minHeight: 6),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (data.canReceive) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('${AppRoutes.purchaseOrders}/$purchaseOrderId/receive'),
                  icon: const Icon(Icons.inventory_outlined),
                  label: Text(l10n.receiveGoods),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
