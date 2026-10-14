import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/reports.dart';
import '../export/report_pdf.dart';
import '../providers/report_providers.dart';
import '../widgets/report_scaffold.dart';

/// Expense report (product spec §49): totals, breakdown by category, by
/// payment method and by day, PDF-exportable.
class ExpensesReportScreen extends ConsumerWidget {
  const ExpensesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.expensesReport,
      body: (context, ref, window) {
        final provider = expensesReportProvider(window.toRange());
        return ReportBody<ExpensesReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _ExpensesBody(data: data, window: window),
        );
      },
    );
  }
}

class _ExpensesBody extends StatelessWidget {
  final ExpensesReportData data;
  final ReportWindow window;

  const _ExpensesBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final maxCategory = data.byCategory.fold<double>(
      0,
      (m, r) => r.amount.toDouble() > m ? r.amount.toDouble() : m,
    );
    final maxDay = data.byDay.fold<double>(
      0,
      (m, r) => r.amount.toDouble() > m ? r.amount.toDouble() : m,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${fmt.format(window.from)} – ${fmt.format(window.to)}',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 12),
        KpiGrid(children: [
          KpiTile(
            label: l10n.total,
            value: money(data.totals.total),
            icon: Icons.payments_outlined,
            accent: Colors.orange,
          ),
          KpiTile(
            label: l10n.entries,
            value: formatInt(data.totals.count),
            icon: Icons.receipt_long_outlined,
          ),
          KpiTile(
            label: l10n.byCategory,
            value: formatInt(data.byCategory.length),
            icon: Icons.category_outlined,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.byCategory,
          child: data.byCategory.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.byCategory)
                      BarRow(
                        label: '${row.category} (${row.entries})',
                        value: money(row.amount),
                        fraction: maxCategory == 0 ? 0 : row.amount.toDouble() / maxCategory,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.paymentMethods,
          child: data.byPaymentMethod.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.byPaymentMethod)
                      BarRow(
                        label: row.method,
                        value: money(row.amount),
                        fraction: 0,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.byDay,
          child: data.byDay.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.byDay)
                      BarRow(
                        label: DateFormat.MMMd().format(row.day),
                        value: money(row.amount),
                        fraction: maxDay == 0 ? 0 : row.amount.toDouble() / maxDay,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.expensesReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            summary: [
              [l10n.total, money(data.totals.total)],
              [l10n.entries, formatInt(data.totals.count)],
            ],
            headers: [l10n.category, l10n.entries, l10n.total],
            rows: [
              for (final row in data.byCategory)
                [row.category, formatInt(row.entries), money(row.amount)],
            ],
          ),
        ),
      ],
    );
  }
}
