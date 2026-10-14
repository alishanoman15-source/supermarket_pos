import 'package:decimal/decimal.dart';
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
import '../../../data/models/customer.dart';
import '../../../data/providers.dart';
import '../providers/parties_providers.dart';

/// Customer detail (SPEC §44) + loyalty ledger and point redemption (§46).
class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  Future<void> _redeem(BuildContext context, WidgetRef ref, Customer customer) async {
    final l10n = context.l10n;
    final points = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.redeem),
        content: AppDecimalField(
          controller: points,
          label: '${l10n.points} (${l10n.balanceAfter}: ${formatQty(customer.loyaltyPoints)})',
          required: true,
          requiredMessage: l10n.required,
          invalidMessage: l10n.invalidNumber,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.redeem)),
        ],
      ),
    );
    if (confirmed != true) return;
    final parsed = Decimal.tryParse(points.text.trim());
    if (parsed == null || parsed <= Decimal.zero) {
      if (context.mounted) showSnack(context, l10n.invalidNumber);
      return;
    }
    try {
      await ref.read(partiesRepositoryProvider).redeemLoyaltyPoints(
            customerId: customer.id,
            points: parsed,
          );
      ref.invalidate(customerProvider(customer.id));
      ref.invalidate(loyaltyTransactionsProvider(customer.id));
      if (context.mounted) showSnack(context, l10n.saved);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final customer = ref.watch(customerProvider(customerId));
    final loyalty = ref.watch(loyaltyTransactionsProvider(customerId));
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customerDetail),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('${AppRoutes.customers}/$customerId/edit'),
          ),
        ],
      ),
      body: AsyncView<Customer?>(
        value: customer,
        onRetry: () => ref.invalidate(customerProvider(customerId)),
        builder: (data) {
          if (data == null) return Center(child: Text(l10n.productNotFound));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: data.name,
                child: Column(
                  children: [
                    if (data.phone != null) DetailRow(label: l10n.phone, value: data.phone!),
                    if (data.email != null) DetailRow(label: l10n.email, value: data.email!),
                    DetailRow(
                      label: l10n.loyaltyPoints,
                      value: formatQty(data.loyaltyPoints),
                      emphasize: true,
                    ),
                    DetailRow(label: l10n.creditLimit, value: money(data.creditLimit)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.loyaltyTransactions,
                trailing: TextButton.icon(
                  onPressed: () => _redeem(context, ref, data),
                  icon: const Icon(Icons.redeem_outlined, size: 18),
                  label: Text(l10n.redeem),
                ),
                child: loyalty.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(e is AppException ? e.message : l10n.somethingWentWrong),
                  data: (rows) => rows.isEmpty
                      ? Text(l10n.noLoyaltyActivity)
                      : Column(
                          children: [
                            for (final tx in rows)
                              DetailRow(
                                label: '${tx.type} · ${dt.format(tx.createdAt)}',
                                value: '${formatQty(tx.points)} → ${formatQty(tx.balanceAfter)}',
                              ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
