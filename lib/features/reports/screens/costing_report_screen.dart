import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/reports.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';
import '../widgets/report_scaffold.dart';

/// Costing & margin report (SPEC §55): weighted-average cost and price changes.
class CostingReportScreen extends ConsumerWidget {
  const CostingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.costingReport,
      showDateRange: false,
      body: (context, ref, window) {
        final provider = costingReportProvider(window.branchId);
        return ReportBody<CostingReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _CostingBody(data: data),
        );
      },
    );
  }
}

class _CostingBody extends StatelessWidget {
  final CostingReportData data;

  const _CostingBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final totalPotential = data.products.fold(
      Decimal.zero,
      (sum, row) => sum + row.potentialProfit,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KpiGrid(children: [
          KpiTile(
            label: l10n.byProduct,
            value: formatInt(data.products.length),
            icon: Icons.inventory_2_outlined,
          ),
          KpiTile(
            label: l10n.potentialProfit,
            value: money(totalPotential),
            icon: Icons.trending_up,
            accent: Colors.green,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.marginPct,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: data.products.isEmpty
              ? Padding(padding: const EdgeInsets.all(8), child: Text(l10n.noData))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.byProduct)),
                      DataColumn(label: Text(l10n.cost), numeric: true),
                      DataColumn(label: Text(l10n.sellingPrice), numeric: true),
                      DataColumn(label: Text(l10n.marginPct), numeric: true),
                      DataColumn(label: Text(l10n.potentialProfit), numeric: true),
                    ],
                    rows: [
                      for (final row in data.products.take(100))
                        DataRow(cells: [
                          DataCell(SizedBox(width: 160, child: Text(row.name))),
                          DataCell(Text(money(row.wac))),
                          DataCell(Text(money(row.sellingPrice))),
                          DataCell(Text('${row.marginPct.toString()}%')),
                          DataCell(Text(money(row.potentialProfit))),
                        ]),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.priceHistory,
          child: data.priceHistory.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.priceHistory.take(30))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.name),
                                  Text(fmt.format(row.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Text(
                              '${money(row.oldPurchasePrice)} → ${money(row.newPurchasePrice)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.costingReport,
            summary: [[l10n.potentialProfit, money(totalPotential)]],
            headers: [
              l10n.byProduct,
              l10n.cost,
              l10n.sellingPrice,
              l10n.marginPct,
              l10n.potentialProfit,
            ],
            rows: [
              for (final row in data.products.take(200))
                [
                  row.name,
                  money(row.wac),
                  money(row.sellingPrice),
                  '${row.marginPct.toString()}%',
                  money(row.potentialProfit),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
