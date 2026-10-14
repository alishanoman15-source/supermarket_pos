import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product.dart';
import '../../../data/models/supplier.dart';
import '../../../data/providers.dart';
import '../../parties/providers/parties_providers.dart';
import '../../products/widgets/product_picker.dart';
import '../providers/purchasing_providers.dart';

/// A single editable line on the order.
class _OrderLine {
  final Product product;
  final TextEditingController qty;
  final TextEditingController cost;
  final TextEditingController tax;

  _OrderLine(this.product, {String qty = '1'})
      : qty = TextEditingController(text: qty),
        cost = TextEditingController(text: (product.purchasePrice ?? Decimal.zero).toString()),
        tax = TextEditingController(text: product.taxRate.toString());

  void dispose() {
    qty.dispose();
    cost.dispose();
    tax.dispose();
  }

  Decimal get qtyValue => Decimal.tryParse(qty.text.trim()) ?? Decimal.zero;
  Decimal get costValue => Decimal.tryParse(cost.text.trim()) ?? Decimal.zero;
  Decimal get taxValue => Decimal.tryParse(tax.text.trim()) ?? Decimal.zero;

  Decimal get lineTotal => roundMoney(qtyValue * costValue);
  Decimal get taxTotal =>
      roundMoney(divideDecimal(qtyValue * costValue * taxValue, hundred));
}

/// New purchase order (SPEC §37).
class PurchaseOrderFormScreen extends ConsumerStatefulWidget {
  const PurchaseOrderFormScreen({super.key});

  @override
  ConsumerState<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends ConsumerState<PurchaseOrderFormScreen> {
  final _note = TextEditingController();
  final _lines = <_OrderLine>[];
  String? _supplierId;
  DateTime? _expectedAt;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Decimal get _subtotal =>
      _lines.fold(Decimal.zero, (sum, l) => sum + l.lineTotal);
  Decimal get _taxTotal => _lines.fold(Decimal.zero, (sum, l) => sum + l.taxTotal);

  Future<void> _addLine() async {
    final product = await showProductPicker(context, ref);
    if (product == null) return;
    if (_lines.any((l) => l.product.id == product.id)) {
      if (mounted) showSnack(context, context.l10n.alreadyAdded);
      return;
    }
    setState(() => _lines.add(_OrderLine(product)));
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_supplierId == null) {
      showSnack(context, l10n.required);
      return;
    }
    if (_lines.isEmpty) {
      showSnack(context, l10n.cartEmpty);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(purchasingRepositoryProvider).createPurchaseOrder(
            supplierId: _supplierId!,
            expectedAt: _expectedAt == null
                ? null
                : DateFormat('yyyy-MM-dd').format(_expectedAt!),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            items: [
              for (final line in _lines)
                {
                  'product_id': line.product.id,
                  'qty': line.qtyValue.toString(),
                  'unit_cost': line.costValue.toString(),
                  'tax_rate': line.taxValue.toString(),
                },
            ],
          );
      ref.invalidate(purchaseOrdersControllerProvider);
      if (mounted) {
        showSnack(context, l10n.orderCreated);
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
    final suppliers = ref.watch(supplierOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.newPurchaseOrder)),
      body: AsyncView<List<Supplier>>(
        value: suppliers,
        onRetry: () => ref.invalidate(supplierOptionsProvider),
        builder: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // An order always belongs to a supplier (SPEC §37). With no
            // suppliers in the business a bare dropdown opens an empty menu
            // and looks broken — offer the create flow instead.
            if (list.isEmpty)
              _SupplierPickerEmpty(
                onAdd: () async {
                  await context.push(AppRoutes.supplierNew);
                  if (mounted) ref.invalidate(supplierOptionsProvider);
                },
              )
            else
              AppDropdown<String>(
                label: l10n.supplier,
                required: true,
                value: _supplierId,
                items: [
                  for (final s in list)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _supplierId = v),
              ),
            const SizedBox(height: 12),
            AppDateField(
              label: l10n.expectedDate,
              value: _expectedAt,
              onChanged: (v) => setState(() => _expectedAt = v),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _note, label: l10n.note, maxLines: 2),
            const SizedBox(height: 16),
            SectionCard(
              title: l10n.orderLines,
              trailing: TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addLine),
              ),
              child: _lines.isEmpty
                  ? Text(l10n.noData)
                  : Column(
                      children: [
                        for (final line in _lines)
                          _LineEditor(
                            line: line,
                            onRemove: () => setState(() {
                              line.dispose();
                              _lines.remove(line);
                            }),
                            onChanged: () => setState(() {}),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: l10n.total,
              child: Column(
                children: [
                  DetailRow(label: l10n.subtotal, value: money(_subtotal)),
                  DetailRow(label: l10n.tax, value: money(_taxTotal)),
                  const Divider(),
                  DetailRow(
                    label: l10n.total,
                    value: money(_subtotal + _taxTotal),
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.create),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for the supplier picker: explains why the field is unusable
/// and links straight into the create-supplier flow instead of showing a
/// dropdown that opens an empty menu.
class _SupplierPickerEmpty extends StatelessWidget {
  final Future<void> Function() onAdd;

  const _SupplierPickerEmpty({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.supplier} *',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_mall_directory_outlined,
                  size: 22,
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.noSuppliers,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addSupplier),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineEditor extends StatelessWidget {
  final _OrderLine line;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _LineEditor({required this.line, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(line.product.name,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppDecimalField(
                  controller: line.qty,
                  label: l10n.qty,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppDecimalField(
                  controller: line.cost,
                  label: l10n.unitCost,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppDecimalField(
                  controller: line.tax,
                  label: l10n.taxRate,
                  onChanged: (_) => onChanged(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${l10n.lineTotal}: ${money(line.lineTotal)}'),
          ),
        ],
      ),
    );
  }
}
