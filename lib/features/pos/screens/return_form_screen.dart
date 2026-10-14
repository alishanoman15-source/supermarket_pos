import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/sale.dart';
import '../../../data/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/pos_providers.dart';

/// Return/refund form (SPEC §11, screen #49). Refund amount and approval
/// threshold are enforced by `return_sale` server-side.
class ReturnFormScreen extends ConsumerStatefulWidget {
  final String saleId;

  const ReturnFormScreen({super.key, required this.saleId});

  @override
  ConsumerState<ReturnFormScreen> createState() => _ReturnFormScreenState();
}

class _ReturnFormScreenState extends ConsumerState<ReturnFormScreen> {
  static const _methods = ['cash', 'card', 'mobile_wallet', 'other'];

  final _reason = TextEditingController();
  final Map<String, TextEditingController> _qty = {};
  Map<String, Decimal> _returned = const {};
  String _method = 'cash';
  bool _busy = false;
  bool _loaded = false;

  @override
  void dispose() {
    _reason.dispose();
    for (final controller in _qty.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Decimal _remaining(SaleItem item) {
    final already = _returned[item.id] ?? Decimal.zero;
    final left = item.qty - already;
    return left < Decimal.zero ? Decimal.zero : left;
  }

  Future<void> _submit(List<SaleItem> items) async {
    final l10n = context.l10n;
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      _snack(l10n.reasonRequired);
      return;
    }

    final payload = <Map<String, dynamic>>[];
    for (final item in items) {
      final value = Decimal.tryParse(_qty[item.id]?.text.trim() ?? '');
      if (value == null || value <= Decimal.zero) continue;
      if (value > _remaining(item)) {
        _snack(l10n.returnTooLarge);
        return;
      }
      payload.add({'sale_item_id': item.id, 'qty': value.toString()});
    }
    if (payload.isEmpty) {
      _snack(l10n.selectAtLeastOneItem);
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(posRepositoryProvider).returnSale(
            saleId: widget.saleId,
            reason: reason,
            items: payload,
            refundMethod: _method,
            idempotencyKey: const Uuid().v4(),
          );
      ref.invalidate(saleProvider(widget.saleId));
      ref.invalidate(saleReturnsProvider(widget.saleId));
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final itemsAsync = ref.watch(saleItemsProvider(widget.saleId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.returnItems)),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is AppException ? error.message : l10n.somethingWentWrong),
        ),
        data: (items) {
          _ensureLoaded(items);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.nameSnapshot),
                  subtitle: Text('${l10n.sold}: ${formatQty(item.qty)} · '
                      '${l10n.returned}: ${formatQty(_returned[item.id] ?? Decimal.zero)}'),
                  trailing: SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _qty[item.id],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: l10n.qty),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _reason,
                decoration: InputDecoration(labelText: l10n.reason),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: InputDecoration(labelText: l10n.refundMethod),
                items: [
                  for (final m in _methods)
                    DropdownMenuItem(value: m, child: Text(_methodLabel(l10n, m))),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : () => _submit(items),
                child: _busy
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.submitReturn),
              ),
            ],
          );
        },
      ),
    );
  }

  void _ensureLoaded(List<SaleItem> items) {
    if (_loaded) return;
    _loaded = true;
    for (final item in items) {
      _qty[item.id] = TextEditingController(text: '0');
    }
    ref.read(posRepositoryProvider).fetchReturnedQuantities(widget.saleId).then((value) {
      if (mounted) setState(() => _returned = value);
    });
  }

  String _methodLabel(AppLocalizations l10n, String method) => switch (method) {
        'cash' => l10n.payCash,
        'card' => l10n.payCard,
        'mobile_wallet' => l10n.payWallet,
        _ => l10n.payOther,
      };
}
