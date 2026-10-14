import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../providers/inventory_providers.dart';

/// Stock transfers list with a receive action (SPEC §13, screen #33).
class TransferListScreen extends ConsumerWidget {
  const TransferListScreen({super.key});

  Future<void> _receive(BuildContext context, WidgetRef ref, String transferId) async {
    try {
      await ref.read(inventoryRepositoryProvider).receiveTransfer(transferId);
      ref.invalidate(stockTransfersProvider);
      ref.invalidate(onHandControllerProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.saved)));
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final transfers = ref.watch(stockTransfersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockTransfers)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.stockTransferNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.newTransfer),
      ),
      body: transfers.when(
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
                  const Icon(Icons.swap_horiz_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(l10n.noResults, textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transfer = items[index];
                  return ListTile(
                    title: Text('#${transfer.id.substring(0, 8)}'),
                    subtitle: Text('${transfer.fromBranchId} → ${transfer.toBranchId}'),
                    trailing: transfer.status == 'in_transit'
                        ? TextButton(
                            onPressed: () => _receive(context, ref, transfer.id),
                            child: Text(l10n.receive),
                          )
                        : Text(transfer.status),
                  );
                },
              ),
      ),
    );
  }
}
