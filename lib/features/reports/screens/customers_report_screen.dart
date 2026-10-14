import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/reports.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';
import '../widgets/report_scaffold.dart';

/// Customer report (product spec §49): invoices, revenue, outstanding balance
/// and loyalty points per customer, PDF-exportable.
class CustomersReportScreen extends ConsumerWidget {
  const CustomersReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.customersReport,
      showBranch: false,
      body: (context, ref, window) {
        final provider = customersReportProvider(window.toRange());
        return ReportBody<CustomersReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _CustomersBody(data: data, window: window),
        );
      },
    );
  }
}

class _CustomersBody extends StatelessWidget {
  final CustomersReportData data;
  final ReportWindow window;

  const _CustomersBody({required this.data, required this.window});

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
            label: l10n.customers,
            value: formatInt(data.totals.customers),
            icon: Icons.people_outline,
          ),
          KpiTile(
            label: l10n.invoices,
            value: formatInt(data.totals.invoices),
            icon: Icons.receipt_long_outlined,
          ),
          KpiTile(
            label: l10n.revenue,
            value: money(data.totals.revenue),
            icon: Icons.payments_outlined,
            accent: Colors.green.shade600,
          ),
          KpiTile(
            label: l10n.loyaltyPoints,
            value: formatInt(data.totals.loyaltyPoints.toDouble()),
            icon: Icons.stars_outlined,
            accent: Colors.orange,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.customers,
          child: data.rows.isEmpty
              ? Text(l10n.noData)
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(l10n.name)),
                      DataColumn(label: Text(l10n.invoices), numeric: true),
                      DataColumn(label: Text(l10n.revenue), numeric: true),
                      DataColumn(label: Text(l10n.outstanding), numeric: true),
                      DataColumn(label: Text(l10n.loyaltyPoints), numeric: true),
                    ],
                    rows: [
                      for (final row in data.rows)
                        DataRow(cells: [
                          DataCell(Text(row.name)),
                          DataCell(Text(formatInt(row.invoices))),
                          DataCell(Text(money(row.revenue))),
                          DataCell(Text(money(row.outstanding))),
                          DataCell(Text(formatInt(row.loyaltyPoints.toDouble()))),
                        ]),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.customersReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [
              [l10n.customers, formatInt(data.totals.customers)],
              [l10n.revenue, money(data.totals.revenue)],
            ],
            headers: [
              l10n.name,
              l10n.invoices,
              l10n.revenue,
              l10n.outstanding,
              l10n.loyaltyPoints,
            ],
            rows: [
              for (final row in data.rows)
                [
                  row.name,
                  formatInt(row.invoices),
                  money(row.revenue),
                  money(row.outstanding),
                  formatInt(row.loyaltyPoints.toDouble()),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
