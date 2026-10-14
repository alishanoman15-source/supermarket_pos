import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/access/access_policy.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/dashboard_kpis.dart';
import '../../auth/providers/permissions_controller.dart';
import '../providers/dashboard_provider.dart';

/// Owner/manager dashboard — the app's command centre (SPEC §31, product
/// spec §7). One scroll: hero revenue card → quick actions → sales windows →
/// revenue chart → orders → P&L → inventory health → breakdowns → best
/// sellers.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kpis = ref.watch(dashboardKpisProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboard)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardKpisProvider),
        child: kpis.when(
          loading: () => const LoadingSkeleton(),
          error: (error, _) => ErrorState(
            message: error is AppException ? error.message : l10n.somethingWentWrong,
            onRetry: () => ref.invalidate(dashboardKpisProvider),
          ),
          data: (data) => _KpiBody(kpis: data),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------
class _KpiBody extends ConsumerWidget {
  final DashboardKpis kpis;

  const _KpiBody({required this.kpis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final access = ref.watch(accessPolicyProvider);
    final maxRevenue = kpis.topProducts.isEmpty
        ? Decimal.one
        : kpis.topProducts
            .map((p) => p.revenue)
            .reduce((a, b) => a > b ? a : b);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // ---- Headline -----------------------------------------------------
        _HeroCard(kpis: kpis),
        const SizedBox(height: 16),
        _QuickActions(access: access),
        const SizedBox(height: 20),

        // ---- Sales windows ------------------------------------------------
        SectionCard(
          title: l10n.sales,
          child: KpiGrid(
            children: [
              KpiTile(
                label: l10n.today,
                value: formatMoney(kpis.sales.today),
                icon: Icons.today_outlined,
              ),
              KpiTile(
                label: l10n.yesterday,
                value: formatMoney(kpis.sales.yesterday),
                icon: Icons.history_outlined,
              ),
              KpiTile(
                label: l10n.last7Days,
                value: formatMoney(kpis.sales.week),
                icon: Icons.date_range_outlined,
                accent: scheme.tertiary,
              ),
              KpiTile(
                label: l10n.thisMonth,
                value: formatMoney(kpis.sales.month),
                icon: Icons.calendar_month_outlined,
              ),
              KpiTile(
                label: l10n.totalSales,
                value: formatMoney(kpis.sales.total),
                icon: Icons.stacked_line_chart,
                accent: scheme.primary,
              ),
            ],
          ),
        ),

        // ---- Orders --------------------------------------------------------
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.orders,
          child: KpiGrid(
            children: [
              KpiTile(
                label: l10n.totalInvoices,
                value: formatInt(kpis.orders.total),
                icon: Icons.receipt_outlined,
              ),
              KpiTile(
                label: l10n.completedSales,
                value: formatInt(kpis.orders.completed),
                icon: Icons.check_circle_outline,
                accent: Colors.green.shade600,
              ),
              KpiTile(
                label: l10n.returnedSales,
                value: formatInt(kpis.orders.returned),
                icon: Icons.undo_outlined,
                accent: scheme.tertiary,
              ),
              KpiTile(
                label: l10n.cancelledSales,
                value: formatInt(kpis.orders.cancelled),
                icon: Icons.cancel_outlined,
                accent: scheme.error,
              ),
            ],
          ),
        ),

        // ---- Profit & loss -------------------------------------------------
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.financials,
          child: _PnlLadder(financials: kpis.financials),
        ),

        // ---- Inventory health ----------------------------------------------
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.inventory,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KpiGrid(
                children: [
                  KpiTile(
                    label: l10n.totalProducts,
                    value: formatInt(kpis.inventory.totalProducts),
                    icon: Icons.inventory_2_outlined,
                  ),
                  KpiTile(
                    label: l10n.stockUnits,
                    value: formatQty(kpis.inventory.totalStockUnits),
                    icon: Icons.warehouse_outlined,
                    accent: scheme.tertiary,
                  ),
                  KpiTile(
                    label: l10n.lowStockCount,
                    value: formatInt(kpis.inventory.lowStockCount),
                    icon: Icons.warning_amber_rounded,
                    accent: kpis.inventory.lowStockCount > 0
                        ? Colors.orange.shade700
                        : null,
                  ),
                  KpiTile(
                    label: l10n.outOfStockCount,
                    value: formatInt(kpis.inventory.outOfStockCount),
                    icon: Icons.remove_shopping_cart_outlined,
                    accent: kpis.inventory.outOfStockCount > 0
                        ? scheme.error
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AlertPill(
                    icon: Icons.hourglass_bottom_outlined,
                    label: l10n.expiringIn7,
                    count: kpis.inventory.expiringWithin7Days,
                    color: Colors.orange.shade700,
                  ),
                  _AlertPill(
                    icon: Icons.hourglass_top_outlined,
                    label: l10n.expiringIn30,
                    count: kpis.inventory.expiringWithin30Days,
                    color: scheme.tertiary,
                  ),
                  _AlertPill(
                    icon: Icons.event_busy_outlined,
                    label: l10n.expired,
                    count: kpis.inventory.expiredBatches,
                    color: scheme.error,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---- Revenue chart -------------------------------------------------
        if (kpis.salesByDay.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.salesByDay,
            trailing: Text(
              formatMoney(_sum(kpis.salesByDay)),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
            ),
            child: _BarChart(points: kpis.salesByDay),
          ),
        ],

        // ---- Breakdowns -----------------------------------------------------
        if (kpis.salesByMonth.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.salesByMonth,
            child: _BarChart(points: kpis.salesByMonth, monthly: true),
          ),
        ],
        if (kpis.salesByCategory.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.salesByCategory,
            child: _SliceList(
              rows: [
                for (final slice in kpis.salesByCategory)
                  (slice.category, slice.revenue),
              ],
            ),
          ),
        ],
        if (kpis.paymentMethods.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.paymentMethods,
            child: _SliceList(
              rows: [
                for (final slice in kpis.paymentMethods)
                  (slice.method, slice.amount),
              ],
            ),
          ),
        ],

        // ---- Best sellers ----------------------------------------------------
        const SizedBox(height: 16),
        SectionCard(
          title: l10n.topProducts,
          child: kpis.topProducts.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      l10n.noSalesYet,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < kpis.topProducts.length; i++)
                      _TopProductRow(
                        rank: i + 1,
                        product: kpis.topProducts[i],
                        maxRevenue: maxRevenue,
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  static Decimal _sum(List<SeriesPoint> points) =>
      points.fold(Decimal.zero, (total, p) => total + p.revenue);
}

// ---------------------------------------------------------------------------
// Hero card — today's revenue with a trend pill and three mini stats
// ---------------------------------------------------------------------------
class _HeroCard extends StatelessWidget {
  final DashboardKpis kpis;

  const _HeroCard({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final trend = _trendPercent(kpis);
    final up = (trend ?? 0) >= 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.30)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -70,
            child: _Glow(size: 180, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            left: -40,
            bottom: -80,
            child: _Glow(size: 160, color: Colors.white.withValues(alpha: 0.07)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.revenueToday,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                      ),
                    ),
                    if (trend != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              up ? Icons.trending_up : Icons.trending_down,
                              size: 16,
                              color: up
                                  ? Colors.greenAccent.shade400
                                  : Colors.redAccent.shade200,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _trendLabel(trend),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formatMoney(kpis.revenue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: l10n.transactionsToday,
                        value: formatInt(kpis.transactions),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: l10n.grossProfit,
                        value: formatMoney(kpis.grossProfit),
                      ),
                    ),
                    Expanded(
                      child: _MiniStat(
                        label: l10n.lowStockItems,
                        value: formatInt(kpis.lowStockCount),
                        highlight: kpis.lowStockCount > 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Percentage change vs the previous period, or null when there is no
  /// meaningful baseline to compare against.
  static double? _trendPercent(DashboardKpis kpis) {
    final previous = kpis.previousRevenue.toDouble();
    if (previous <= 0) return null;
    return (kpis.revenue.toDouble() - previous) / previous * 100;
  }

  static String _trendLabel(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}% vs previous';
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _MiniStat({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: highlight ? Colors.orange.shade200 : Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.75),
              ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions — permission-aware shortcuts to the modules
// ---------------------------------------------------------------------------
class _QuickActions extends StatelessWidget {
  final AccessPolicy access;

  const _QuickActions({required this.access});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = <(IconData, String, String)>[
      (Icons.point_of_sale_outlined, l10n.pos, AppRoutes.pos),
      (Icons.inventory_2_outlined, l10n.products, AppRoutes.products),
      (Icons.warehouse_outlined, l10n.inventory, AppRoutes.inventory),
      (Icons.receipt_long_outlined, l10n.sales, AppRoutes.sales),
      (Icons.bar_chart_outlined, l10n.reports, AppRoutes.reports),
      (Icons.more_horiz, l10n.more, AppRoutes.more),
    ];
    final visible = actions.where((a) => access.canOpen(a.$3)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (icon, label, route) in visible)
          _ActionChip(
            icon: icon,
            label: label,
            onTap: () => context.go(route),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts & breakdowns
// ---------------------------------------------------------------------------
/// Column chart with gradient bars — day/month revenue series.
class _BarChart extends StatelessWidget {
  final List<SeriesPoint> points;
  final bool monthly;

  const _BarChart({required this.points, this.monthly = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) return const SizedBox.shrink();

    // Buckets that actually sold keep the chart readable; fall back to the
    // most recent points when the whole window is empty.
    final selling = points.where((p) => p.revenue > Decimal.zero).toList();
    final rows = (selling.isEmpty ? points : selling)
        .toList()
        .reversed
        .take(monthly ? 12 : 7)
        .toList()
        .reversed
        .toList();
    final maxRevenue = rows
        .map((p) => p.revenue)
        .reduce((a, b) => a > b ? a : b);
    final dayFormat = DateFormat.MMMd();
    final monthFormat = DateFormat.MMM();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 148,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in rows)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FractionallySizedBox(
                      alignment: Alignment.bottomCenter,
                      heightFactor: maxRevenue <= Decimal.zero
                          ? 0.04
                          : (point.revenue / maxRevenue)
                              .toDouble()
                              .clamp(0.04, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.45),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final point in rows)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    monthly
                        ? monthFormat.format(point.date)
                        : dayFormat.format(point.date),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Horizontal bars for a name → amount breakdown (categories, tenders).
class _SliceList extends StatelessWidget {
  final List<(String, Decimal)> rows;

  const _SliceList({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final maxValue = rows.map((r) => r.$2).reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final (label, value) in rows)
          BarRow(
            label: label,
            value: formatMoney(value),
            fraction: maxValue <= Decimal.zero ? 0 : (value / maxValue).toDouble(),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Profit & loss ladder
// ---------------------------------------------------------------------------
class _PnlLadder extends StatelessWidget {
  final Financials financials;

  const _PnlLadder({required this.financials});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final net = financials.netProfit;
    final positive = net >= Decimal.zero;

    return Column(
      children: [
        _PnlRow(label: l10n.revenue, value: formatMoney(financials.revenue)),
        _PnlRow(
          label: l10n.cogs,
          value: formatMoney(financials.costOfGoods),
          muted: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(color: scheme.outlineVariant, height: 1),
        ),
        _PnlRow(
          label: l10n.grossProfit,
          value: formatMoney(financials.grossProfit),
          color: Colors.green.shade700,
          bold: true,
        ),
        _PnlRow(
          label: l10n.expensesTotal,
          value: formatMoney(financials.expenses),
          color: scheme.error,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Divider(color: scheme.outlineVariant, height: 1),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: positive
                ? Colors.green.shade50
                : scheme.error.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: positive
                  ? Colors.green.shade200
                  : scheme.error.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 18,
                color: positive ? Colors.green.shade700 : scheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.netProfit,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: positive ? Colors.green.shade900 : scheme.error,
                      ),
                ),
              ),
              Text(
                formatMoney(net),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: positive ? Colors.green.shade800 : scheme.error,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PnlRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;
  final bool muted;

  const _PnlRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelColor = color ??
        (muted ? scheme.onSurfaceVariant : scheme.onSurface);
    final valueColor = color ??
        (muted ? scheme.onSurfaceVariant : scheme.onSurface);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: valueColor,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Inventory alert pill
// ---------------------------------------------------------------------------
class _AlertPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _AlertPill({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final silent = count == 0;
    final effective = silent ? Theme.of(context).colorScheme.outline : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: effective.withValues(alpha: silent ? 0.05 : 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effective.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: effective),
          const SizedBox(width: 8),
          Text(
            formatInt(count),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: effective,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ranked best sellers
// ---------------------------------------------------------------------------
class _TopProductRow extends StatelessWidget {
  final int rank;
  final TopProduct product;
  final Decimal maxRevenue;

  const _TopProductRow({
    required this.rank,
    required this.product,
    required this.maxRevenue,
  });

  static const List<Color> _medals = [
    Color(0xFFE9B949), // gold
    Color(0xFF98A2B3), // silver
    Color(0xFFD97A34), // bronze
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = rank <= 3 ? _medals[rank - 1] : scheme.primary;
    final fraction =
        maxRevenue <= Decimal.zero ? 0.0 : (product.revenue / maxRevenue).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badge.withValues(alpha: rank <= 3 ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(10),
              border: rank <= 3
                  ? Border.all(color: badge.withValues(alpha: 0.55))
                  : null,
            ),
            child: Text(
              '$rank',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: rank <= 3 ? badge : scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BarRow(
              label: product.name,
              value: formatMoney(product.revenue),
              fraction: fraction,
              color: rank <= 3 ? badge : scheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${formatQty(product.qtySold)} ×',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
