import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

class TopProduct {
  final String name;
  final Decimal qtySold;
  final Decimal revenue;

  const TopProduct({required this.name, required this.qtySold, required this.revenue});

  factory TopProduct.fromMap(Map<String, dynamic> map) => TopProduct(
        name: (map['name'] as String?) ?? '',
        qtySold: decimalFrom(map['qty_sold']),
        revenue: decimalFrom(map['revenue']),
      );
}

/// Headline sales windows (today / yesterday / last 7 days / month to date /
/// lifetime) — product spec §7 "Sales".
class SalesWindows {
  final Decimal today;
  final Decimal yesterday;
  final Decimal week;
  final Decimal month;
  final Decimal total;

  const SalesWindows({
    required this.today,
    required this.yesterday,
    required this.week,
    required this.month,
    required this.total,
  });

  SalesWindows.empty()
      : today = Decimal.zero,
        yesterday = Decimal.zero,
        week = Decimal.zero,
        month = Decimal.zero,
        total = Decimal.zero;

  factory SalesWindows.fromMap(Map<String, dynamic>? map) {
    if (map == null) return SalesWindows.empty();
    return SalesWindows(
      today: decimalFrom(map['today']),
      yesterday: decimalFrom(map['yesterday']),
      week: decimalFrom(map['week']),
      month: decimalFrom(map['month']),
      total: decimalFrom(map['total']),
    );
  }
}

/// Invoice lifecycle counters for the reporting period — product spec §7
/// "Orders".
class OrderCounts {
  final int total;
  final int completed;
  final int returned;
  final int cancelled;

  const OrderCounts({
    required this.total,
    required this.completed,
    required this.returned,
    required this.cancelled,
  });

  OrderCounts.empty()
      : total = 0,
        completed = 0,
        returned = 0,
        cancelled = 0;

  factory OrderCounts.fromMap(Map<String, dynamic>? map) {
    if (map == null) return OrderCounts.empty();
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return OrderCounts(
      total: read('total'),
      completed: read('completed'),
      returned: read('returned'),
      cancelled: read('cancelled'),
    );
  }
}

/// Stock health snapshot — product spec §7 "Inventory".
class InventoryHealth {
  final int totalProducts;
  final Decimal totalStockUnits;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiredBatches;
  final int expiringWithin7Days;
  final int expiringWithin30Days;

  const InventoryHealth({
    required this.totalProducts,
    required this.totalStockUnits,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.expiredBatches,
    required this.expiringWithin7Days,
    required this.expiringWithin30Days,
  });

  InventoryHealth.empty()
      : totalProducts = 0,
        totalStockUnits = Decimal.zero,
        lowStockCount = 0,
        outOfStockCount = 0,
        expiredBatches = 0,
        expiringWithin7Days = 0,
        expiringWithin30Days = 0;

  factory InventoryHealth.fromMap(Map<String, dynamic>? map) {
    if (map == null) return InventoryHealth.empty();
    final expiring = Map<String, dynamic>.from(
      (map['expiring'] as Map?) ?? const {},
    );
    int read(String key) => (map[key] as num?)?.toInt() ?? 0;
    return InventoryHealth(
      totalProducts: read('total_products'),
      totalStockUnits: decimalFrom(map['total_stock_units']),
      lowStockCount: read('low_stock_count'),
      outOfStockCount: read('out_of_stock_count'),
      expiredBatches: (expiring['expired'] as num?)?.toInt() ?? 0,
      expiringWithin7Days: (expiring['within_7_days'] as num?)?.toInt() ?? 0,
      expiringWithin30Days: (expiring['within_30_days'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Profit & loss for the reporting period — product spec §7 "Financial".
class Financials {
  final Decimal revenue;
  final Decimal costOfGoods;
  final Decimal grossProfit;
  final Decimal expenses;
  final Decimal netProfit;

  const Financials({
    required this.revenue,
    required this.costOfGoods,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
  });

  Financials.empty()
      : revenue = Decimal.zero,
        costOfGoods = Decimal.zero,
        grossProfit = Decimal.zero,
        expenses = Decimal.zero,
        netProfit = Decimal.zero;

  factory Financials.fromMap(Map<String, dynamic>? map) {
    if (map == null) return Financials.empty();
    return Financials(
      revenue: decimalFrom(map['revenue']),
      costOfGoods: decimalFrom(map['cost_of_goods']),
      grossProfit: decimalFrom(map['gross_profit']),
      expenses: decimalFrom(map['expenses']),
      netProfit: decimalFrom(map['net_profit']),
    );
  }
}

/// One bucket of a dashboard time series (`sales_by_day` / `sales_by_month`).
class SeriesPoint {
  final DateTime date;
  final int transactions;
  final Decimal revenue;

  const SeriesPoint({
    required this.date,
    required this.transactions,
    required this.revenue,
  });

  factory SeriesPoint.fromMap(Map<String, dynamic> map) => SeriesPoint(
        date: DateTime.tryParse((map['day'] ?? map['month'] ?? '').toString()) ??
            DateTime.now(),
        transactions: (map['transactions'] as num?)?.toInt() ?? 0,
        revenue: decimalFrom(map['revenue']),
      );
}

/// Revenue grouped by product category (`sales_by_category`).
class CategorySlice {
  final String category;
  final Decimal qtySold;
  final Decimal revenue;

  const CategorySlice({
    required this.category,
    required this.qtySold,
    required this.revenue,
  });

  factory CategorySlice.fromMap(Map<String, dynamic> map) => CategorySlice(
        category: (map['category'] as String?) ?? '',
        qtySold: decimalFrom(map['qty_sold']),
        revenue: decimalFrom(map['revenue']),
      );
}

/// Split of takings by tender type (`payment_methods`).
class PaymentSlice {
  final String method;
  final Decimal amount;
  final int payments;

  const PaymentSlice({
    required this.method,
    required this.amount,
    required this.payments,
  });

  factory PaymentSlice.fromMap(Map<String, dynamic> map) => PaymentSlice(
        method: (map['method'] as String?) ?? '',
        amount: decimalFrom(map['amount']),
        payments: (map['payments'] as num?)?.toInt() ?? 0,
      );
}

class DashboardKpis {
  final Decimal revenue;
  final Decimal previousRevenue;
  final int transactions;
  final Decimal grossProfit;
  final int lowStockCount;
  final List<TopProduct> topProducts;

  final SalesWindows sales;
  final OrderCounts orders;
  final InventoryHealth inventory;
  final Financials financials;

  final List<SeriesPoint> salesByDay;
  final List<SeriesPoint> salesByMonth;
  final List<CategorySlice> salesByCategory;
  final List<PaymentSlice> paymentMethods;

  const DashboardKpis({
    required this.revenue,
    required this.previousRevenue,
    required this.transactions,
    required this.grossProfit,
    required this.lowStockCount,
    required this.topProducts,
    required this.sales,
    required this.orders,
    required this.inventory,
    required this.financials,
    required this.salesByDay,
    required this.salesByMonth,
    required this.salesByCategory,
    required this.paymentMethods,
  });

  static List<Map<String, dynamic>> _rows(Object? value) => [
        for (final row in (value as List?) ?? const [])
          Map<String, dynamic>.from(row as Map),
      ];

  factory DashboardKpis.fromData(Map<String, dynamic> data) {
    final charts = Map<String, dynamic>.from(
      (data['charts'] as Map?) ?? const {},
    );
    return DashboardKpis(
      revenue: decimalFrom(data['revenue']),
      previousRevenue: decimalFrom(data['previous_revenue']),
      transactions: (data['transactions'] as num?)?.toInt() ?? 0,
      grossProfit: decimalFrom(data['gross_profit']),
      lowStockCount: (data['low_stock_count'] as num?)?.toInt() ?? 0,
      topProducts: _rows(data['top_products']).map(TopProduct.fromMap).toList(),
      sales: SalesWindows.fromMap(
        (data['sales'] as Map?) == null
            ? null
            : Map<String, dynamic>.from(data['sales'] as Map),
      ),
      orders: OrderCounts.fromMap(
        (data['orders'] as Map?) == null
            ? null
            : Map<String, dynamic>.from(data['orders'] as Map),
      ),
      inventory: InventoryHealth.fromMap(
        (data['inventory'] as Map?) == null
            ? null
            : Map<String, dynamic>.from(data['inventory'] as Map),
      ),
      financials: Financials.fromMap(
        (data['financials'] as Map?) == null
            ? null
            : Map<String, dynamic>.from(data['financials'] as Map),
      ),
      salesByDay:
          _rows(charts['sales_by_day']).map(SeriesPoint.fromMap).toList(),
      salesByMonth:
          _rows(charts['sales_by_month']).map(SeriesPoint.fromMap).toList(),
      salesByCategory:
          _rows(charts['sales_by_category']).map(CategorySlice.fromMap).toList(),
      paymentMethods:
          _rows(charts['payment_methods']).map(PaymentSlice.fromMap).toList(),
    );
  }
}
