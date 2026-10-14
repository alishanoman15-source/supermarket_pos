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

/// Profit report (SPEC §61): revenue, COGS, gross profit, refunds, expenses.
class ProfitReportScreen extends ConsumerWidget {
  const ProfitReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.profitReport,
      body: (context, ref, window) {
        final provider = profitReportProvider(window.toRange());
        return ReportBody<ProfitReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _ProfitBody(data: data, window: window),
        );
      },
    );
  }
}

class _ProfitBody extends StatelessWidget {
  final ProfitReportData data;
  final ReportWindow window;

  const _ProfitBody({required this.data, required this.window});

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
            label: l10n.revenue,
            value: money(data.revenue),
            icon: Icons.payments_outlined,
          ),
          KpiTile(
            label: l10n.cogs,
            value: money(data.cogs),
            icon: Icons.inventory_2_outlined,
            accent: Colors.orange,
          ),
          KpiTile(
            label: l10n.grossProfit,
            value: money(data.grossProfit),
            icon: Icons.trending_up,
            accent: Colors.green,
          ),
          KpiTile(
            label: l10n.operatingProfit,
            value: money(data.operatingProfit),
            icon: Icons.account_balance_outlined,
            accent: data.operatingProfit >= Decimal.zero ? Colors.green : Colors.red,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.total,
          child: Column(
            children: [
              DetailRow(label: l10n.netSales, value: money(data.revenue)),
              DetailRow(label: l10n.taxCollected, value: money(data.taxCollected)),
              DetailRow(label: l10n.cogs, value: '− ${money(data.cogs)}'),
              const Divider(),
              DetailRow(label: l10n.grossProfit, value: money(data.grossProfit), emphasize: true),
              DetailRow(label: l10n.refundsTotal, value: '− ${money(data.refunds)}'),
              DetailRow(label: l10n.expensesTotal, value: '− ${money(data.expenses)}'),
              const Divider(),
              DetailRow(
                label: l10n.operatingProfit,
                value: money(data.operatingProfit),
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.profitReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [
              [l10n.revenue, money(data.revenue)],
              [l10n.grossProfit, money(data.grossProfit)],
              [l10n.operatingProfit, money(data.operatingProfit)],
            ],
            headers: [l10n.name, l10n.amount],
            rows: [
              [l10n.netSales, money(data.revenue)],
              [l10n.taxCollected, money(data.taxCollected)],
              [l10n.cogs, money(data.cogs)],
              [l10n.grossProfit, money(data.grossProfit)],
              [l10n.refundsTotal, money(data.refunds)],
              [l10n.expensesTotal, money(data.expenses)],
              [l10n.operatingProfit, money(data.operatingProfit)],
            ],
          ),
        ),
      ],
    );
  }
}
