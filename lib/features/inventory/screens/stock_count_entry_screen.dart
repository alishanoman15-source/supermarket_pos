import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/inventory.dart';
import '../../../data/providers.dart';
import '../providers/inventory_providers.dart';

/// Enters counted quantities for a draft count, submits it, then approves it
/// (approval generates `count_correction` movements server-side).
class StockCountEntryScreen extends ConsumerStatefulWidget {
  final String stockCountId;

  const StockCountEntryScreen({super.key, required this.stockCountId});

  @override
  ConsumerState<StockCountEntryScreen> createState() => _StockCountEntryScreenState();
}

class _StockCountEntryScreenState extends ConsumerState<StockCountEntryScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> _payload() {
    final rows = <Map<String, dynamic>>[];
    _controllers.forEach((productId, controller) {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      final qty = Decimal.tryParse(text);
      if (qty == null) return;
      rows.add({'product_id': productId, 'counted_qty': qty.toString()});
    });
    return rows;
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final rows = _payload();
    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.required)));
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(inventoryRepositoryProvider).submitStockCount(widget.stockCountId, rows);
      ref.invalidate(stockCountsProvider);
      ref.invalidate(stockCountItemsProvider(widget.stockCountId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await ref.read(inventoryRepositoryProvider).approveStockCount(widget.stockCountId);
      ref.invalidate(stockCountsProvider);
      ref.invalidate(onHandControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.saved)));
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(stockCountItemsProvider(widget.stockCountId));
    final catalog = ref.watch(onHandCatalogProvider).valueOrNull ?? const <StockRecord>[];
    final nameById = {for (final r in catalog) r.productId: r.name};

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stockCountEntry)),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(e is AppException ? e.message : l10n.somethingWentWrong, textAlign: TextAlign.center),
          ),
        ),
        data: (rows) => rows.isEmpty
            ? Center(child: Text(l10n.noResults))
            : ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final item = rows[index];
                  final controller = _controllers.putIfAbsent(
                    item.productId,
                    () => TextEditingController(
                      text: item.countedQty?.toString() ?? '',
                    ),
                  );
                  return ListTile(
                    title: Text(nameById[item.productId] ?? l10n.noResults),
                    subtitle: Text('${l10n.systemQty}: ${item.systemQty}'),
                    trailing: SizedBox(
                      width: 120,
                      child: TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(labelText: '?'),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _approve,
                  child: Text(l10n.approve),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.submit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
