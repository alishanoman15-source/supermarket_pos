import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/reports.dart';
import '../../../data/providers.dart';

/// Immutable key for the date-ranged report families.
class ReportRange {
  final DateTime from;
  final DateTime to;
  final String? branchId;

  const ReportRange({required this.from, required this.to, this.branchId});

  @override
  bool operator ==(Object other) =>
      other is ReportRange &&
      other.from == from &&
      other.to == to &&
      other.branchId == branchId;

  @override
  int get hashCode => Object.hash(from, to, branchId);
}

class SalesReportParams {
  final ReportRange range;
  final String groupBy;

  const SalesReportParams({required this.range, this.groupBy = 'day'});

  @override
  bool operator ==(Object other) =>
      other is SalesReportParams && other.range == range && other.groupBy == groupBy;

  @override
  int get hashCode => Object.hash(range, groupBy);
}

final salesReportProvider =
    FutureProvider.autoDispose.family<SalesReportData, SalesReportParams>((ref, p) {
  return ref.watch(reportsRepositoryProvider).sales(
        from: p.range.from,
        to: p.range.to,
        branchId: p.range.branchId,
        groupBy: p.groupBy,
      );
});

final profitReportProvider =
    FutureProvider.autoDispose.family<ProfitReportData, ReportRange>((ref, r) {
  return ref
      .watch(reportsRepositoryProvider)
      .profit(from: r.from, to: r.to, branchId: r.branchId);
});

final inventoryReportProvider =
    FutureProvider.autoDispose.family<InventoryReportData, String?>((ref, branchId) {
  return ref.watch(reportsRepositoryProvider).inventory(branchId: branchId);
});

final purchasesReportProvider =
    FutureProvider.autoDispose.family<PurchasesReportData, ReportRange>((ref, r) {
  return ref
      .watch(reportsRepositoryProvider)
      .purchases(from: r.from, to: r.to, branchId: r.branchId);
});

final cashReportProvider =
    FutureProvider.autoDispose.family<CashReportData, ReportRange>((ref, r) {
  return ref
      .watch(reportsRepositoryProvider)
      .cash(from: r.from, to: r.to, branchId: r.branchId);
});

final costingReportProvider =
    FutureProvider.autoDispose.family<CostingReportData, String?>((ref, branchId) {
  return ref.watch(reportsRepositoryProvider).costing(branchId: branchId);
});

final expensesReportProvider =
    FutureProvider.autoDispose.family<ExpensesReportData, ReportRange>((ref, r) {
  return ref
      .watch(reportsRepositoryProvider).expenses(from: r.from, to: r.to, branchId: r.branchId);
});

final suppliersReportProvider =
    FutureProvider.autoDispose.family<SuppliersReportData, ReportRange>((ref, r) {
  return ref.watch(reportsRepositoryProvider).suppliers(from: r.from, to: r.to);
});

final customersReportProvider =
    FutureProvider.autoDispose.family<CustomersReportData, ReportRange>((ref, r) {
  return ref.watch(reportsRepositoryProvider).customers(from: r.from, to: r.to);
});

final productsReportProvider =
    FutureProvider.autoDispose.family<ProductsReportData, ReportRange>((ref, r) {
  return ref.watch(reportsRepositoryProvider).products(
        from: r.from,
        to: r.to,
        branchId: r.branchId,
      );
});
