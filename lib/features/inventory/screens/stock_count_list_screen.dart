import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../providers/inventory_providers.dart';

/// Stock counts: start one, then open its entry screen (SPEC §13, screen #31).
class StockCountListScreen extends ConsumerWidget {
  const StockCountListScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final noteController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.startStockCount),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(labelText: l10n.note),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final countId = await ref
          .read(inventoryRepositoryProvider)
          .startStockCount(note: noteController.text.trim());
      ref.invalidate(stockCountsProvider);
      if (context.mounted) context.push('${AppRoutes.stockCountEntry}/$countId');
    } on AppException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final counts = ref.watch(stockCountsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockCounts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _start(context, ref),
        icon: const Icon(Icons.play_arrow),
        label: Text(l10n.startStockCount),
      ),
      body: counts.when(
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
                  const Icon(Icons.checklist_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(l10n.noResults, textAlign: TextAlign.center),
                ],
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final count = items[index];
                  return ListTile(
                    title: Text('#${count.id.substring(0, 8)}'),
                    subtitle: Text([count.status, if (count.note != null) count.note!].join(' · ')),
                    trailing: _StatusChip(status: count.status),
                    onTap: () => context.push('${AppRoutes.stockCountEntry}/${count.id}'),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => Colors.green,
      'submitted' => Colors.blue,
      'cancelled' => Colors.red,
      _ => Colors.orange,
    };
    return Chip(label: Text(status), visualDensity: VisualDensity.compact, side: BorderSide(color: color));
  }
}
