import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/shift.dart';
import '../../../data/providers.dart';
import '../providers/shift_providers.dart';

/// Cash movements / drawer detail (SPEC §52): review every movement on a shift
/// and record drawer-in / drawer-out.
class CashDrawerScreen extends ConsumerWidget {
  final String shiftId;

  const CashDrawerScreen({super.key, required this.shiftId});

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final amount = TextEditingController();
    final note = TextEditingController();
    String type = 'drawer_in';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.recordMovement),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'drawer_in', label: Text(l10n.cashIn)),
                  ButtonSegment(value: 'drawer_out', label: Text(l10n.cashOut)),
                ],
                selected: {type},
                onSelectionChanged: (v) => setState(() => type = v.first),
              ),
              const SizedBox(height: 12),
              AppDecimalField(
                controller: amount,
                label: l10n.amount,
                required: true,
                requiredMessage: l10n.required,
                invalidMessage: l10n.invalidNumber,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: note, label: l10n.note),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final parsed = Decimal.tryParse(amount.text.trim());
    if (parsed == null || parsed <= Decimal.zero) {
      if (context.mounted) showSnack(context, l10n.invalidNumber);
      return;
    }
    try {
      await ref.read(shiftRepositoryProvider).recordCashMovement(
            shiftId: shiftId,
            type: type,
            amount: parsed,
            note: note.text.trim().isEmpty ? null : note.text.trim(),
          );
      ref.invalidate(cashMovementsProvider(shiftId));
      if (context.mounted) showSnack(context, l10n.saved);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final movements = ref.watch(cashMovementsProvider(shiftId));
    final dt = DateFormat.yMMMd().add_Hm();
    final shift = ref
        .watch(shiftsProvider)
        .valueOrNull
        ?.where((s) => s.id == shiftId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashDrawer)),
      body: AsyncView<List<CashMovement>>(
        value: movements,
        onRetry: () => ref.invalidate(cashMovementsProvider(shiftId)),
        builder: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (shift != null)
              SectionCard(
                title: l10n.shiftSummary,
                trailing: StatusChip(status: shift.status),
                child: Column(
                  children: [
                    DetailRow(label: l10n.openingFloat, value: money(shift.openingFloat)),
                    if (shift.expectedCash != null)
                      DetailRow(label: l10n.expectedCash, value: money(shift.expectedCash!)),
                    if (shift.variance != null)
                      DetailRow(label: l10n.variance, value: money(shift.variance!)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            SectionCard(
              title: l10n.movements,
              child: items.isEmpty
                  ? Text(l10n.noData)
                  : Column(
                      children: [
                        for (final movement in items)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              movement.type == 'drawer_in' || movement.type == 'sale'
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: movement.type == 'drawer_in' || movement.type == 'sale'
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.error,
                            ),
                            title: Text(movement.type.replaceAll('_', ' ')),
                            subtitle: Text(
                              movement.note?.isNotEmpty == true
                                  ? movement.note!
                                  : dt.format(movement.createdAt),
                            ),
                            trailing: Text(money(movement.amount),
                                style: Theme.of(context).textTheme.titleSmall),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: shift != null && shift.isOpen
          ? FloatingActionButton.extended(
              onPressed: () => _record(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.recordMovement),
            )
          : null,
    );
  }
}
