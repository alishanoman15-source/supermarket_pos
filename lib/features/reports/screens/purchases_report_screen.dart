import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/reports.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';
import '../widgets/report_scaffold.dart';

/// Purchases / suppliers report (SPEC §63) including unpaid bills and ageing.
class PurchasesReportScreen extends ConsumerWidget {
  const PurchasesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.purchasesReport,
      body: (context, ref, window) {
        final provider = purchasesReportProvider(window.toRange());
        return ReportBody<PurchasesReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _PurchasesBody(data: data, window: window),
        );
      },
    );
  }
}

class _PurchasesBody extends StatelessWidget {
  final PurchasesReportData data;
  final ReportWindow window;

  const _PurchasesBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final maxTotal = data.bySupplier.fold<double>(
      0,
      (m, r) => r.total.toDouble() > m ? r.total.toDouble() : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${fmt.format(window.from)} – ${fmt.format(window.to)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        KpiGrid(children: [
          KpiTile(
            label: l10n.totalPurchases,
            value: money(data.totalPurchases),
            icon: Icons.local_shipping_outlined,
          ),
          KpiTile(
            label: l10n.bySupplier,
            value: formatInt(data.bySupplier.length),
            icon: Icons.store_mall_directory_outlined,
          ),
          KpiTile(
            label: l10n.unpaidBills,
            value: formatInt(data.unpaidBills.length),
            icon: Icons.receipt_long_outlined,
            accent: Colors.orange,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.bySupplier,
          child: data.bySupplier.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.bySupplier)
                      BarRow(
                        label: '${row.name} (${row.bills})',
                        value: money(row.total),
                        fraction: maxTotal == 0 ? 0 : row.total.toDouble() / maxTotal,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.unpaidBills,
          child: data.unpaidBills.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final bill in data.unpaidBills.take(30))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(bill.supplierName,
                                      style: Theme.of(context).textTheme.bodyLarge),
                                  Text(
                                    '${bill.billNumber ?? '—'}'
                                    '${bill.dueAt != null ? ' · ${fmt.format(bill.dueAt!)}' : ''}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(money(bill.balance),
                                    style: Theme.of(context).textTheme.titleSmall),
                                Text('${l10n.total} ${money(bill.total)}',
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        if (data.supplierAgeing.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.bucket0_30,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(l10n.supplier)),
                  DataColumn(label: Text(l10n.bucket0_30), numeric: true),
                  DataColumn(label: Text(l10n.bucket30_60), numeric: true),
                  DataColumn(label: Text(l10n.bucket60_90), numeric: true),
                  DataColumn(label: Text(l10n.bucket90Plus), numeric: true),
                ],
                rows: [
                  for (final row in data.supplierAgeing)
                    DataRow(cells: [
                      DataCell(Text(row.name)),
                      DataCell(Text(money(row.b0To30))),
                      DataCell(Text(money(row.b30To60))),
                      DataCell(Text(money(row.b60To90))),
                      DataCell(Text(money(row.b90Plus))),
                    ]),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.purchasesReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [[l10n.totalPurchases, money(data.totalPurchases)]],
            headers: [l10n.supplier, l10n.count, l10n.total],
            rows: [
              for (final row in data.bySupplier) [row.name, '${row.bills}', money(row.total)],
            ],
          ),
        ),
      ],
    );
  }
}
