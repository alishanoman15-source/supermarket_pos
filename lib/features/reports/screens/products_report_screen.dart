import 'package:decimal/decimal.dart';
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

/// Product performance report (product spec §52): units sold, revenue, cost,
/// profit, margin and current stock per product, PDF-exportable.
class ProductsReportScreen extends ConsumerWidget {
  const ProductsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.productsReport,
      body: (context, ref, window) {
        final provider = productsReportProvider(window.toRange());
        return ReportBody<ProductsReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _ProductsBody(data: data, window: window),
        );
      },
    );
  }
}

class _ProductsBody extends StatelessWidget {
  final ProductsReportData data;
  final ReportWindow window;

  const _ProductsBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final profit = data.totals.revenue - data.totals.cost;
    final maxRevenue = data.rows.fold<Decimal>(
      Decimal.zero,
      (m, r) => r.revenue > m ? r.revenue : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${fmt.format(window.from)} – ${fmt.format(window.to)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        KpiGrid(children: [
          KpiTile(
            label: l10n.revenue,
            value: money(data.totals.revenue),
            icon: Icons.payments_outlined,
          ),
          KpiTile(
            label: l10n.cogs,
            value: money(data.totals.cost),
            icon: Icons.shopping_cart_outlined,
          ),
          KpiTile(
            label: l10n.profit,
            value: money(profit),
            icon: Icons.trending_up,
            accent: profit < Decimal.zero ? Colors.red : Colors.green.shade600,
          ),
          KpiTile(
            label: l10n.unitsSold,
            value: formatQty(data.totals.qtySold),
            icon: Icons.inventory_2_outlined,
            accent: Theme.of(context).colorScheme.tertiary,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.productsReport,
          child: data.rows.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.rows.take(50))
                      BarRow(
                        label: '${row.name} (${formatQty(row.qtySold)})',
                        value: money(row.revenue),
                        fraction: maxRevenue <= Decimal.zero
                            ? 0
                            : (row.revenue / maxRevenue).toDouble(),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.marginPct,
          child: data.rows.isEmpty
              ? Text(l10n.noData)
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.name)),
                      DataColumn(label: Text(l10n.unitsSold), numeric: true),
                      DataColumn(label: Text(l10n.revenue), numeric: true),
                      DataColumn(label: Text(l10n.profit), numeric: true),
                      DataColumn(label: Text(l10n.marginPct), numeric: true),
                      DataColumn(label: Text(l10n.stockOnHand), numeric: true),
                    ],
                    rows: [
                      for (final row in data.rows)
                        DataRow(cells: [
                          DataCell(Text(row.name)),
                          DataCell(Text(formatQty(row.qtySold))),
                          DataCell(Text(money(row.revenue))),
                          DataCell(Text(money(row.profit))),
                          DataCell(Text('${row.marginPct.toString()}%')),
                          DataCell(Text(formatQty(row.onHand))),
                        ]),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.productsReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [
              [l10n.revenue, money(data.totals.revenue)],
              [l10n.cogs, money(data.totals.cost)],
              [l10n.profit, money(profit)],
            ],
            headers: [
              l10n.name,
              l10n.unitsSold,
              l10n.revenue,
              l10n.profit,
              l10n.marginPct,
              l10n.stockOnHand,
            ],
            rows: [
              for (final row in data.rows)
                [
                  row.name,
                  formatQty(row.qtySold),
                  money(row.revenue),
                  money(row.profit),
                  '${row.marginPct.toString()}%',
                  formatQty(row.onHand),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
