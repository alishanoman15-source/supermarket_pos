import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';
import '../providers/inventory_providers.dart';

/// Manual stock adjustment (SPEC §13, screen #30). Writes go through the
/// `adjust_stock` RPC, which always creates exactly one movement row.
class StockAdjustmentScreen extends ConsumerStatefulWidget {
  final String productId;

  const StockAdjustmentScreen({super.key, required this.productId});

  @override
  ConsumerState<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends ConsumerState<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(inventoryRepositoryProvider).adjustStock(
            productId: widget.productId,
            qtyDelta: Decimal.parse(_qty.text.trim()),
            reason: _reason.text.trim(),
          );
      ref.invalidate(stockRecordProvider(widget.productId));
      ref.invalidate(stockMovementsProvider(widget.productId));
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adjustStock)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _qty,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.qtyDelta,
                    helperText: l10n.qtyDeltaHelp,
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return l10n.required;
                    if (Decimal.tryParse(v) == null) return l10n.invalidNumber;
                    if (Decimal.parse(v) == Decimal.zero) return l10n.invalidNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reason,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(labelText: l10n.reason),
                  validator: (v) => Validators.requiredText(v, message: l10n.required),
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
        ),
      ),
    );
  }
}
