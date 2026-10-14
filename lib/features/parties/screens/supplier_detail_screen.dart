import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/supplier.dart';
import '../../../data/providers.dart';
import '../providers/parties_providers.dart';

/// Supplier detail (SPEC §40): contact info, balance and payment history.
class SupplierDetailScreen extends ConsumerWidget {
  final String supplierId;

  const SupplierDetailScreen({super.key, required this.supplierId});

  Future<void> _pay(BuildContext context, WidgetRef ref, Supplier supplier) async {
    final l10n = context.l10n;
    final amount = TextEditingController();
    final reference = TextEditingController();
    String method = 'cash';

    final recorded = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.paySupplier),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDecimalField(
                controller: amount,
                label: l10n.amount,
                required: true,
                requiredMessage: l10n.required,
                invalidMessage: l10n.invalidNumber,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: InputDecoration(labelText: l10n.paymentMethod),
                items: [
                  DropdownMenuItem(value: 'cash', child: Text(l10n.payCash)),
                  DropdownMenuItem(value: 'card', child: Text(l10n.payCard)),
                  DropdownMenuItem(value: 'bank_transfer', child: Text(l10n.bankTransfer)),
                  DropdownMenuItem(value: 'mobile_wallet', child: Text(l10n.payWallet)),
                  DropdownMenuItem(value: 'other', child: Text(l10n.payOther)),
                ],
                onChanged: (v) => setState(() => method = v ?? 'cash'),
              ),
              const SizedBox(height: 12),
              AppTextField(controller: reference, label: l10n.reference),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );

    if (recorded != true) return;
    final parsed = Decimal.tryParse(amount.text.trim());
    if (parsed == null || parsed <= Decimal.zero) {
      if (context.mounted) showSnack(context, l10n.invalidNumber);
      return;
    }
    try {
      await ref.read(partiesRepositoryProvider).paySupplier(
            supplierId: supplier.id,
            amount: parsed,
            method: method,
            reference: reference.text.trim().isEmpty ? null : reference.text.trim(),
            idempotencyKey: const Uuid().v4(),
          );
      ref.invalidate(supplierPaymentsProvider(supplier.id));
      if (context.mounted) showSnack(context, l10n.saved);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final supplier = ref.watch(supplierProvider(supplierId));
    final payments = ref.watch(supplierPaymentsProvider(supplierId));
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.supplierDetail),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('${AppRoutes.suppliers}/$supplierId/edit'),
          ),
        ],
      ),
      body: AsyncView<Supplier?>(
        value: supplier,
        onRetry: () => ref.invalidate(supplierProvider(supplierId)),
        builder: (data) {
          if (data == null) {
            return Center(child: Text(l10n.productNotFound));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: data.name,
                trailing: StatusChip(status: data.status),
                child: Column(
                  children: [
                    if (data.contactPerson != null)
                      DetailRow(label: l10n.contactPerson, value: data.contactPerson!),
                    if (data.phone != null) DetailRow(label: l10n.phone, value: data.phone!),
                    if (data.email != null) DetailRow(label: l10n.email, value: data.email!),
                    if (data.address != null) DetailRow(label: l10n.address, value: data.address!),
                    DetailRow(
                      label: l10n.openingBalance,
                      value: money(data.openingBalance),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.payments,
                trailing: TextButton.icon(
                  onPressed: () => _pay(context, ref, data),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(l10n.paySupplier),
                ),
                child: payments.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(e is AppException ? e.message : l10n.somethingWentWrong),
                  data: (rows) => rows.isEmpty
                      ? Text(l10n.noData)
                      : Column(
                          children: [
                            for (final p in rows)
                              DetailRow(
                                label: '${p.method.replaceAll('_', ' ')} · ${dt.format(p.paidAt)}',
                                value: money(p.amount),
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
