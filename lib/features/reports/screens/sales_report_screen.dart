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

/// Sales report (SPEC §60) with day/week/month grouping and PDF export.
class SalesReportScreen extends ConsumerStatefulWidget {
  const SalesReportScreen({super.key});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  String _groupBy = 'day';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.salesReport,
      actions: [
        PopupMenuButton<String>(
          tooltip: l10n.groupBy,
          initialValue: _groupBy,
          onSelected: (v) => setState(() => _groupBy = v),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'day', child: Text(l10n.day)),
            PopupMenuItem(value: 'week', child: Text(l10n.week)),
            PopupMenuItem(value: 'month', child: Text(l10n.month)),
            PopupMenuItem(value: 'hour', child: Text(l10n.hour)),
          ],
        ),
      ],
      body: (context, ref, window) {
        final provider = salesReportProvider(
          SalesReportParams(range: window.toRange(), groupBy: _groupBy),
        );
        return ReportBody<SalesReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _SalesBody(data: data, window: window),
        );
      },
    );
  }
}

class _SalesBody extends StatelessWidget {
  final SalesReportData data;
  final ReportWindow window;

  const _SalesBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final maxRevenue = data.rows.fold<double>(
      0,
      (m, r) => r.revenue.toDouble() > m ? r.revenue.toDouble() : m,
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
            value: money(data.revenue),
            icon: Icons.payments_outlined,
          ),
          KpiTile(
            label: l10n.transactions,
            value: formatInt(data.transactions),
            icon: Icons.receipt_outlined,
          ),
          KpiTile(
            label: l10n.avgBasket,
            value: money(data.transactions == 0
                ? Decimal.zero
                : divideDecimal(data.revenue, Decimal.fromInt(data.transactions))),
            icon: Icons.shopping_basket_outlined,
          ),
          KpiTile(
            label: l10n.itemsPerTxn,
            value: data.itemsPerTxn.toString(),
            icon: Icons.inventory_2_outlined,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.total,
          child: Column(
            children: [
              DetailRow(label: l10n.grossSales, value: money(data.grossSales)),
              DetailRow(label: l10n.discounts, value: '− ${money(data.discounts)}'),
              DetailRow(label: l10n.netSales, value: money(data.netSales)),
              DetailRow(label: l10n.taxCollected, value: money(data.taxCollected)),
              const Divider(),
              DetailRow(label: l10n.revenue, value: money(data.revenue), emphasize: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.byDay,
          child: data.rows.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.rows)
                      BarRow(
                        label: _bucketLabel(row.bucket),
                        value: money(row.revenue),
                        fraction: maxRevenue == 0 ? 0 : row.revenue.toDouble() / maxRevenue,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.salesReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)} · ${data.groupBy}',
            summary: [
              [l10n.revenue, money(data.revenue)],
              [l10n.transactions, formatInt(data.transactions)],
              [l10n.grossSales, money(data.grossSales)],
              [l10n.taxCollected, money(data.taxCollected)],
            ],
            headers: [l10n.date, l10n.transactions, l10n.grossSales, l10n.discounts, l10n.revenue],
            rows: [
              for (final r in data.rows)
                [
                  _bucketLabel(r.bucket),
                  formatInt(r.transactions),
                  money(r.grossSales),
                  money(r.discounts),
                  money(r.revenue),
                ],
            ],
          ),
        ),
      ],
    );
  }

  String _bucketLabel(DateTime bucket) {
    switch (data.groupBy) {
      case 'hour':
        return DateFormat.MMMd().add_Hm().format(bucket);
      case 'month':
        return DateFormat.yMMM().format(bucket);
      default:
        return DateFormat.yMMMd().format(bucket);
    }
  }
}
