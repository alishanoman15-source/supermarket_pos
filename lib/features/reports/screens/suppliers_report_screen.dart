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

/// Supplier report (product spec §49 / §27): purchases, payments and the
/// outstanding balance per supplier, PDF-exportable.
class SuppliersReportScreen extends ConsumerWidget {
  const SuppliersReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.suppliersReport,
      showBranch: false,
      body: (context, ref, window) {
        final provider = suppliersReportProvider(window.toRange());
        return ReportBody<SuppliersReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _SuppliersBody(data: data, window: window),
        );
      },
    );
  }
}

class _SuppliersBody extends StatelessWidget {
  final SuppliersReportData data;
  final ReportWindow window;

  const _SuppliersBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${fmt.format(window.from)} – ${fmt.format(window.to)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        KpiGrid(children: [
          KpiTile(
            label: l10n.suppliers,
            value: formatInt(data.totals.suppliers),
            icon: Icons.local_shipping_outlined,
          ),
          KpiTile(
            label: l10n.totalPurchases,
            value: money(data.totals.purchases),
            icon: Icons.shopping_cart_outlined,
          ),
          KpiTile(
            label: l10n.amountPaid,
            value: money(data.totals.paid),
            icon: Icons.paid_outlined,
            accent: Colors.green.shade600,
          ),
          KpiTile(
            label: l10n.balanceDue,
            value: money(data.totals.balanceDue),
            icon: Icons.account_balance_wallet_outlined,
            accent: data.totals.balanceDue > Decimal.zero ? Colors.orange : null,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.suppliers,
          child: data.rows.isEmpty
              ? Text(l10n.noData)
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.name)),
                      DataColumn(label: Text(l10n.totalPurchases), numeric: true),
                      DataColumn(label: Text(l10n.amountPaid), numeric: true),
                      DataColumn(label: Text(l10n.balanceDue), numeric: true),
                    ],
                    rows: [
                      for (final row in data.rows)
                        DataRow(cells: [
                          DataCell(Text(row.name)),
                          DataCell(Text(money(row.purchasesTotal))),
                          DataCell(Text(money(row.paidTotal))),
                          DataCell(Text(money(row.balanceDue))),
                        ]),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.suppliersReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [
              [l10n.totalPurchases, money(data.totals.purchases)],
              [l10n.amountPaid, money(data.totals.paid)],
              [l10n.balanceDue, money(data.totals.balanceDue)],
            ],
            headers: [l10n.name, l10n.totalPurchases, l10n.amountPaid, l10n.balanceDue],
            rows: [
              for (final row in data.rows)
                [
                  row.name,
                  money(row.purchasesTotal),
                  money(row.paidTotal),
                  money(row.balanceDue),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
