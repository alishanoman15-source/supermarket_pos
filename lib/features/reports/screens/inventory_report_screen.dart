import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/reports.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';
import '../widgets/report_scaffold.dart';

/// Inventory report (SPEC §62): valuation, low/out of stock, dead stock and
/// expiring batches.
class InventoryReportScreen extends ConsumerWidget {
  const InventoryReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.inventoryReport,
      showDateRange: false,
      body: (context, ref, window) {
        final provider = inventoryReportProvider(window.branchId);
        return ReportBody<InventoryReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _InventoryBody(data: data),
        );
      },
    );
  }
}

class _InventoryBody extends StatelessWidget {
  final InventoryReportData data;

  const _InventoryBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiGrid(children: [
          KpiTile(
            label: l10n.valueAtCost,
            value: money(data.valueAtCost),
            icon: Icons.warehouse_outlined,
          ),
          KpiTile(
            label: l10n.valueAtRetail,
            value: money(data.valueAtRetail),
            icon: Icons.storefront_outlined,
          ),
          KpiTile(
            label: l10n.marginValue,
            value: money(data.marginValue),
            icon: Icons.trending_up,
            accent: Colors.green,
          ),
          KpiTile(
            label: l10n.lowStockCount,
            value: '${data.lowStockCount} / ${data.outOfStockCount}',
            hint: l10n.outOfStockCount,
            icon: Icons.warning_amber_outlined,
            accent: Colors.orange,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.suggestedOrderQty,
          child: data.reorderSuggestions.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.reorderSuggestions)
                      DetailRow(
                        label: row.name,
                        value: formatQty(row.suggestedQty),
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${formatQty(row.onHand)} / ${formatQty(row.reorderLevel)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '→ ${formatQty(row.suggestedQty)}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.deadStock,
          child: data.deadStock.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.deadStock.take(20))
                      DetailRow(
                        label: row.name,
                        value: '${formatQty(row.onHand)} · ${money(row.wac)}',
                        valueWidget: Text(
                          '${formatQty(row.onHand)} × ${money(row.wac)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.expiringSoon,
          child: data.expiring.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.expiring.take(30))
                      DetailRow(
                        label: row.name,
                        value: row.expiryDate == null
                            ? formatQty(row.qty)
                            : '${fmt.format(row.expiryDate!)} · ${formatQty(row.qty)}',
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (row.expiryDate != null)
                              Text(fmt.format(row.expiryDate!)),
                            const SizedBox(width: 8),
                            Text(formatQty(row.qty)),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.inventoryReport,
            summary: [
              [l10n.valueAtCost, money(data.valueAtCost)],
              [l10n.valueAtRetail, money(data.valueAtRetail)],
              [l10n.lowStockCount, '${data.lowStockCount}'],
            ],
            headers: [l10n.name, l10n.qty, l10n.cost],
            rows: [
              for (final row in data.deadStock)
                [row.name, formatQty(row.onHand), money(row.wac)],
            ],
          ),
        ),
        if (data.reorderSuggestions.isNotEmpty)
          ReportExportButton(
            table: () => ExportTable(
              title: l10n.suggestedOrderQty,
              headers: [l10n.name, l10n.stockOnHand, l10n.suggestedOrderQty],
              rows: [
                for (final row in data.reorderSuggestions)
                  [
                    row.name,
                    formatQty(row.onHand),
                    formatQty(row.suggestedQty),
                  ],
              ],
            ),
          ),
      ],
    );
  }
}
