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
import '../../../data/models/inventory.dart';
import '../../../data/models/product.dart';
import '../export/label_pdf.dart';
import '../providers/catalog_providers.dart';
import '../../inventory/providers/inventory_providers.dart';

/// Product detail (SPEC §20): identity, pricing, cost (permission-gated),
/// stock and the recent movement timeline, plus label printing.
class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  Future<void> _printLabel(BuildContext context, WidgetRef ref, Product product) async {
    final l10n = context.l10n;
    final copies = TextEditingController(text: '1');
    final barcode = TextEditingController(text: product.barcode ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.printLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(controller: barcode, label: l10n.barcode),
            const SizedBox(height: 12),
            AppTextField(
              controller: copies,
              label: l10n.copies,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.print)),
        ],
      ),
    );
    if (ok != true) return;
    await printProductLabels(LabelSpec(
      name: product.name,
      barcode: barcode.text.trim().isEmpty ? '—' : barcode.text.trim(),
      price: money(product.sellingPrice),
      copies: int.tryParse(copies.text.trim()) ?? 1,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final product = ref.watch(productDetailProvider(productId));
    final movements = ref.watch(stockMovementsProvider(productId));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final brands = ref.watch(brandsProvider).valueOrNull ?? const [];
    final dt = DateFormat.yMMMd().add_Hm();

    String nameOf(List<dynamic> list, String? id) {
      if (id == null) return '—';
      for (final item in list) {
        if (item.id == id) return item.name as String;
      }
      return '—';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productDetail),
        actions: [
          IconButton(
            tooltip: l10n.printLabel,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () {
              final data = product.valueOrNull;
              if (data != null) _printLabel(context, ref, data);
            },
          ),
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('${AppRoutes.products}/$productId'),
          ),
        ],
      ),
      body: AsyncView<Product?>(
        value: product,
        onRetry: () => ref.invalidate(productDetailProvider(productId)),
        builder: (data) {
          if (data == null) return Center(child: Text(l10n.productNotFound));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: data.name,
                trailing: StatusChip(status: data.status),
                child: Column(
                  children: [
                    if (data.sku?.isNotEmpty == true) DetailRow(label: l10n.sku, value: data.sku!),
                    if (data.barcode?.isNotEmpty == true)
                      DetailRow(label: l10n.barcode, value: data.barcode!),
                    DetailRow(label: l10n.category, value: nameOf(categories, data.categoryId)),
                    DetailRow(label: l10n.brand, value: nameOf(brands, data.brandId)),
                    DetailRow(
                      label: l10n.sellingPrice,
                      value: money(data.sellingPrice),
                      emphasize: true,
                    ),
                    if (data.purchasePrice != null)
                      DetailRow(
                        label: l10n.cost,
                        value: money(data.purchasePrice!),
                        valueWidget: Text(
                          money(data.purchasePrice!),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    DetailRow(label: l10n.taxRate, value: '${data.taxRate.toString()}%'),
                    DetailRow(label: l10n.reorderLevel, value: formatQty(data.reorderLevel)),
                    DetailRow(label: l10n.weightBased, value: data.isWeightBased ? '✓' : '—'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.stockOnHand,
                child: Column(
                  children: [
                    DetailRow(
                      label: l10n.inventory,
                      value: formatQty(data.stock),
                      emphasize: true,
                    ),
                    if (data.isLowStock)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(status: 'inactive', label: l10n.lowStock),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.push('${AppRoutes.stockAdjust}/$productId'),
                            icon: const Icon(Icons.tune, size: 18),
                            label: Text(l10n.adjustStock),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('${AppRoutes.stockProduct}/$productId'),
                            icon: const Icon(Icons.history, size: 18),
                            label: Text(l10n.movements),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.recentMovements,
                child: movements.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(e is AppException ? e.message : l10n.somethingWentWrong),
                  data: (rows) => rows.isEmpty
                      ? Text(l10n.noData)
                      : Column(
                          children: [
                            for (final movement in rows.take(15))
                              _MovementRow(movement: movement, dt: dt),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  final StockMovement movement;
  final DateFormat dt;

  const _MovementRow({required this.movement, required this.dt});

  @override
  Widget build(BuildContext context) {
    final positive = movement.qtyDelta >= Decimal.zero;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        positive ? Icons.arrow_downward : Icons.arrow_upward,
        color: positive ? Colors.green : Theme.of(context).colorScheme.error,
      ),
      title: Text(movement.movementType.replaceAll('_', ' ')),
      subtitle: Text(dt.format(movement.createdAt)),
      trailing: Text(
        formatQty(movement.qtyDelta),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
