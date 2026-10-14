import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/inventory.dart';
import '../../../data/providers.dart';
import '../../setup/providers/branch_provider.dart';
import '../providers/inventory_providers.dart';

/// Creates a transfer: destination branch + lines (screen #34).
class TransferFormScreen extends ConsumerStatefulWidget {
  const TransferFormScreen({super.key});

  @override
  ConsumerState<TransferFormScreen> createState() => _TransferFormScreenState();
}

class _TransferFormScreenState extends ConsumerState<TransferFormScreen> {
  final _note = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _rows = <Map<String, dynamic>>[];
  String? _toBranchId;
  String? _productId;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    _qty.dispose();
    super.dispose();
  }

  void _addItem(StockRecord record) {
    final qty = Decimal.tryParse(_qty.text.trim());
    if (qty == null || qty <= Decimal.zero) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.invalidNumber)));
      return;
    }
    setState(() {
      _rows.add({'product_id': record.productId, 'qty': qty.toString(), 'name': record.name});
      _productId = null;
      _qty.text = '1';
    });
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_toBranchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.required)));
      return;
    }
    if (_rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.required)));
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(inventoryRepositoryProvider).createTransfer(
            toBranchId: _toBranchId!,
            note: _note.text.trim(),
            items: [
              for (final row in _rows)
                {'product_id': row['product_id'], 'qty': row['qty']},
            ],
          );
      ref.invalidate(stockTransfersProvider);
      ref.invalidate(onHandControllerProvider);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    final catalog = ref.watch(onHandCatalogProvider).valueOrNull ?? const <StockRecord>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newTransfer)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String?>(
              initialValue: _toBranchId,
              decoration: InputDecoration(labelText: l10n.toBranch),
              items: [
                for (final branch in branches)
                  DropdownMenuItem(value: branch.id, child: Text(branch.name)),
              ],
              onChanged: (value) => setState(() => _toBranchId = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _productId,
              decoration: InputDecoration(labelText: l10n.products),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('—')),
                for (final record in catalog)
                  DropdownMenuItem<String?>(value: record.productId, child: Text(record.name)),
              ],
              onChanged: (value) => setState(() => _productId = value),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _qty,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: l10n.qty),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _productId == null
                      ? null
                      : () {
                          final record = catalog.firstWhere(
                            (r) => r.productId == _productId,
                            orElse: () => catalog.first,
                          );
                          _addItem(record);
                        },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              decoration: InputDecoration(labelText: l10n.note),
            ),
            const SizedBox(height: 16),
            for (final row in _rows)
              Card(
                child: ListTile(
                  dense: true,
                  title: Text('${row['name']}'),
                  trailing: Text(formatQty(Decimal.parse(row['qty'] as String))),
                  onLongPress: () => setState(() => _rows.remove(row)),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
