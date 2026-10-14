import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/purchase.dart';
import '../../../data/providers.dart';
import '../providers/purchasing_providers.dart';

/// Per-line receive state.
class _ReceiveLine {
  final PurchaseOrderItem item;
  final TextEditingController qty;
  final TextEditingController cost;
  final TextEditingController batchNo;
  DateTime? expiry;

  _ReceiveLine(this.item)
      : qty = TextEditingController(
            text: (item.qty - item.receivedQty) > Decimal.zero
                ? (item.qty - item.receivedQty).toString()
                : '0'),
        cost = TextEditingController(text: item.unitCost.toString()),
        batchNo = TextEditingController();

  void dispose() {
    qty.dispose();
    cost.dispose();
    batchNo.dispose();
  }

  Decimal get qtyValue => Decimal.tryParse(qty.text.trim()) ?? Decimal.zero;
  Decimal get costValue => Decimal.tryParse(cost.text.trim()) ?? Decimal.zero;
}

/// Goods receive against a purchase order (SPEC §38, §55): posts stock and
/// updates the weighted-average cost server-side.
class GoodsReceiveScreen extends ConsumerStatefulWidget {
  final String purchaseOrderId;

  const GoodsReceiveScreen({super.key, required this.purchaseOrderId});

  @override
  ConsumerState<GoodsReceiveScreen> createState() => _GoodsReceiveScreenState();
}

class _GoodsReceiveScreenState extends ConsumerState<GoodsReceiveScreen> {
  List<_ReceiveLine>? _lines;
  bool _busy = false;

  @override
  void dispose() {
    for (final line in _lines ?? const <_ReceiveLine>[]) {
      line.dispose();
    }
    super.dispose();
  }

  void _ensureLines(List<PurchaseOrderItem> items) {
    if (_lines != null) return;
    _lines = [for (final item in items) _ReceiveLine(item)];
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final lines = _lines ?? const <_ReceiveLine>[];
    final receiving = lines.where((l) => l.qtyValue > Decimal.zero).toList();
    if (receiving.isEmpty) {
      showSnack(context, l10n.noData);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(purchasingRepositoryProvider).receivePurchase(
            purchaseOrderId: widget.purchaseOrderId,
            idempotencyKey: const Uuid().v4(),
            items: [
              for (final line in receiving)
                {
                  'product_id': line.item.productId,
                  'qty': line.qtyValue.toString(),
                  'unit_cost': line.costValue.toString(),
                  if (line.batchNo.text.trim().isNotEmpty) 'batch_no': line.batchNo.text.trim(),
                  if (line.expiry != null)
                    'expiry_date':
                        '${line.expiry!.year.toString().padLeft(4, '0')}-'
                            '${line.expiry!.month.toString().padLeft(2, '0')}-'
                            '${line.expiry!.day.toString().padLeft(2, '0')}',
                },
            ],
          );
      ref.invalidate(purchaseOrderProvider(widget.purchaseOrderId));
      ref.invalidate(purchaseOrderItemsProvider(widget.purchaseOrderId));
      ref.invalidate(purchaseOrdersControllerProvider);
      ref.invalidate(purchasesControllerProvider);
      if (mounted) {
        showSnack(context, l10n.goodsReceived);
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = ref.watch(purchaseOrderItemsProvider(widget.purchaseOrderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.goodsReceive)),
      body: AsyncView<List<PurchaseOrderItem>>(
        value: items,
        onRetry: () => ref.invalidate(purchaseOrderItemsProvider(widget.purchaseOrderId)),
        builder: (data) {
          _ensureLines(data);
          final lines = _lines!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final line in lines)
                SectionCard(
                  title: line.item.productName,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppDecimalField(
                              controller: line.qty,
                              label: l10n.receivedQty,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppDecimalField(
                              controller: line.cost,
                              label: l10n.unitCost,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.orderedQty}: ${formatQty(line.item.qty)} · '
                        '${l10n.receivedQty}: ${formatQty(line.item.receivedQty)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: line.batchNo,
                              label: l10n.batchNo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppDateField(
                              label: l10n.expiryDate,
                              value: line.expiry,
                              onChanged: (v) => setState(() => line.expiry = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.inventory_outlined),
                label: _busy
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.receiveGoods),
              ),
            ],
          );
        },
      ),
    );
  }
}
