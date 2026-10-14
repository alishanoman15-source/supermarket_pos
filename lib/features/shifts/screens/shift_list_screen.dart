import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/shift.dart';
import '../providers/shift_providers.dart';

/// Shift history (#53). Shows the cash drawer detail (#52) in a bottom sheet
/// and routes to open (#50) / close (#51).
class ShiftListScreen extends ConsumerWidget {
  const ShiftListScreen({super.key});

  Future<void> _open(BuildContext context) async {
    if (context.mounted) context.push(AppRoutes.shiftNew);
  }

  Future<void> _showDrawer(BuildContext context, WidgetRef ref, Shift shift) async {
    final l10n = context.l10n;
    final movements = ref.read(cashMovementsProvider(shift.id));
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(l10n.cashDrawer, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (shift.isOpen || shift.expectedCash != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text([
                    '${l10n.openingFloat}: ${formatMoney(shift.openingFloat)}',
                    if (shift.expectedCash != null) '${l10n.expectedCash}: ${formatMoney(shift.expectedCash!)}',
                    if (shift.closingCounted != null)
                      '${l10n.countedCash}: ${formatMoney(shift.closingCounted!)}',
                    if (shift.variance != null) '${l10n.variance}: ${formatMoney(shift.variance!)}',
                    if (shift.varianceReason?.isNotEmpty == true)
                      '${l10n.reason}: ${shift.varianceReason}',
                  ].join('\n')),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: movements.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(e is AppException ? e.message : l10n.somethingWentWrong),
                  ),
                  data: (items) => items.isEmpty
                      ? Center(child: Text(l10n.noResults))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final movement = items[index];
                            return ListTile(
                              dense: true,
                              title: Text(movement.type),
                              subtitle: Text(movement.note ?? movement.createdAt.toString().substring(0, 16)),
                              trailing: Text(formatMoney(movement.amount)),
                            );
                          },
                        ),
                ),
              ),
              if (shift.isOpen)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('${AppRoutes.cashDrawer}/${shift.id}');
                          },
                          icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                          label: Text(l10n.cashDrawer),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('${AppRoutes.shiftClose}/${shift.id}');
                          },
                          child: Text(l10n.closeShift),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shifts = ref.watch(shiftsProvider);
    final openShift = ref.watch(myOpenShiftProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shifts)),
      floatingActionButton: openShift == null
          ? FloatingActionButton.extended(
              onPressed: () => _open(context),
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.openShift),
            )
          : null,
      body: shifts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is AppException ? e.message : l10n.somethingWentWrong, textAlign: TextAlign.center),
          ),
        ),
        data: (items) => items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.point_of_sale_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(l10n.noResults, textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final shift = items[index];
                  return ListTile(
                    leading: Icon(
                      shift.isOpen ? Icons.lock_open : Icons.lock_outline,
                      color: shift.isOpen ? Colors.green : null,
                    ),
                    title: Text(shift.isOpen ? l10n.openShift : l10n.closedShift),
                    subtitle: Text(
                      [
                        shift.openedAt.toString().substring(0, 16),
                        if (shift.variance != null) '${l10n.variance}: ${formatMoney(shift.variance!)}',
                      ].join(' · '),
                    ),
                    onTap: () => _showDrawer(context, ref, shift),
                  );
                },
              ),
      ),
    );
  }
}
