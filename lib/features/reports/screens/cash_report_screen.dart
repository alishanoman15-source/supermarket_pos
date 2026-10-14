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

/// Cash & shifts report (SPEC §64): shifts, variances and cashier totals.
class CashReportScreen extends ConsumerWidget {
  const CashReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return ReportScaffold(
      title: l10n.cashReport,
      body: (context, ref, window) {
        final provider = cashReportProvider(window.toRange());
        return ReportBody<CashReportData>(
          value: ref.watch(provider),
          onRetry: () => ref.invalidate(provider),
          builder: (data) => _CashBody(data: data, window: window),
        );
      },
    );
  }
}

class _CashBody extends StatelessWidget {
  final CashReportData data;
  final ReportWindow window;

  const _CashBody({required this.data, required this.window});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    final dt = DateFormat.yMMMd().add_Hm();
    final maxRevenue = data.byCashier.fold<double>(
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
            label: l10n.shifts,
            value: formatInt(data.shifts.length),
            icon: Icons.schedule_outlined,
          ),
          KpiTile(
            label: l10n.variance,
            value: formatInt(data.variances.length),
            hint: l10n.variance,
            icon: Icons.warning_amber_outlined,
            accent: data.variances.isEmpty ? Colors.green : Colors.orange,
          ),
          KpiTile(
            label: l10n.byCashier,
            value: formatInt(data.byCashier.length),
            icon: Icons.people_outline,
          ),
        ]),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.byCashier,
          child: data.byCashier.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final row in data.byCashier)
                      BarRow(
                        label: '${row.cashierName ?? '—'} (${row.transactions})',
                        value: money(row.revenue),
                        fraction: maxRevenue == 0 ? 0 : row.revenue.toDouble() / maxRevenue,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.shifts,
          child: data.shifts.isEmpty
              ? Text(l10n.noData)
              : Column(
                  children: [
                    for (final shift in data.shifts.take(40))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${shift.cashierName ?? '—'}'
                                    '${shift.branchName != null ? ' · ${shift.branchName}' : ''}',
                                  ),
                                  Text(dt.format(shift.openedAt),
                                      style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  shift.expectedCash == null
                                      ? '—'
                                      : money(shift.expectedCash!),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                if (shift.variance != null &&
                                    shift.variance != Decimal.zero)
                                  Text(
                                    '${l10n.variance} ${money(shift.variance!)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            StatusChip(status: shift.status),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        ReportExportButton(
          table: () => ExportTable(
            title: l10n.cashReport,
            subtitle: '${fmt.format(window.from)} – ${fmt.format(window.to)}',
            headers: [l10n.cashier, l10n.date, l10n.expectedCash, l10n.variance],
            rows: [
              for (final shift in data.shifts)
                [
                  shift.cashierName ?? '—',
                  dt.format(shift.openedAt),
                  shift.expectedCash == null ? '—' : money(shift.expectedCash!),
                  shift.variance == null ? '—' : money(shift.variance!),
                ],
            ],
          ),
        ),
      ],
    );
  }
}
