import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/reports.dart';

/// Server-side aggregated reports (SPEC §49–55). Every call is permission
/// gated inside the database; the client never aggregates raw rows.
class ReportsRepository {
  final SupabaseClient _client;

  const ReportsRepository(this._client);

  Map<String, dynamic> _data(Object? res) =>
      Map<String, dynamic>.from((res as Map)['data'] as Map);

  Future<SalesReportData> sales({
    required DateTime from,
    required DateTime to,
    String? branchId,
    String groupBy = 'day',
  }) async {
    try {
      final res = await _client.rpc('report_sales', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
        'p_group_by': groupBy,
      });
      return SalesReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<ProfitReportData> profit({
    required DateTime from,
    required DateTime to,
    String? branchId,
  }) async {
    try {
      final res = await _client.rpc('report_profit', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
      });
      return ProfitReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<InventoryReportData> inventory({
    String? branchId,
    int deadStockDays = 60,
  }) async {
    try {
      final res = await _client.rpc('report_inventory', params: {
        'p_branch': branchId,
        'p_dead_stock_days': deadStockDays,
      });
      return InventoryReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<PurchasesReportData> purchases({
    required DateTime from,
    required DateTime to,
    String? branchId,
  }) async {
    try {
      final res = await _client.rpc('report_purchases', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
      });
      return PurchasesReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<CashReportData> cash({
    required DateTime from,
    required DateTime to,
    String? branchId,
  }) async {
    try {
      final res = await _client.rpc('report_cash', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
      });
      return CashReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<CostingReportData> costing({String? branchId, int limit = 100}) async {
    try {
      final res = await _client.rpc('report_costing', params: {
        'p_branch': branchId,
        'p_limit': limit,
      });
      return CostingReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<ExpensesReportData> expenses({
    required DateTime from,
    required DateTime to,
    String? branchId,
  }) async {
    try {
      final res = await _client.rpc('report_expenses', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
      });
      return ExpensesReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<SuppliersReportData> suppliers({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final res = await _client.rpc('report_suppliers', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
      });
      return SuppliersReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<CustomersReportData> customers({
    required DateTime from,
    required DateTime to,
    int limit = 100,
  }) async {
    try {
      final res = await _client.rpc('report_customers', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_limit': limit,
      });
      return CustomersReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<ProductsReportData> products({
    required DateTime from,
    required DateTime to,
    String? branchId,
    int limit = 100,
  }) async {
    try {
      final res = await _client.rpc('report_products', params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_to': to.toUtc().toIso8601String(),
        'p_branch': branchId,
        'p_limit': limit,
      });
      return ProductsReportData.fromMap(_data(res));
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
