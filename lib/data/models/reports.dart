import 'package:decimal/decimal.dart';

import '../../core/utils/money.dart';

/// Typed views over the reporting RPC payloads (SPEC §49–55).
/// The RPCs return `{ok, data}`; these models parse `data`.

Decimal _d(Object? v) => decimalFrom(v);
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
DateTime _dt(Object? v) =>
    v == null ? DateTime.now() : DateTime.parse(v as String).toLocal();

// ---------------------------------------------------------------------------
// Sales report (§50)
// ---------------------------------------------------------------------------
class SalesReportRow {
  final DateTime bucket;
  final int transactions;
  final Decimal grossSales;
  final Decimal discounts;
  final Decimal netSales;
  final Decimal taxCollected;
  final Decimal revenue;
  final Decimal avgBasket;

  const SalesReportRow({
    required this.bucket,
    required this.transactions,
    required this.grossSales,
    required this.discounts,
    required this.netSales,
    required this.taxCollected,
    required this.revenue,
    required this.avgBasket,
  });

  factory SalesReportRow.fromMap(Map<String, dynamic> m) => SalesReportRow(
        bucket: _dt(m['bucket']),
        transactions: _i(m['transactions']),
        grossSales: _d(m['gross_sales']),
        discounts: _d(m['discounts']),
        netSales: _d(m['net_sales']),
        taxCollected: _d(m['tax_collected']),
        revenue: _d(m['revenue']),
        avgBasket: _d(m['avg_basket']),
      );
}

class SalesReportData {
  final String groupBy;
  final List<SalesReportRow> rows;
  final int transactions;
  final Decimal grossSales;
  final Decimal discounts;
  final Decimal netSales;
  final Decimal taxCollected;
  final Decimal revenue;
  final Decimal itemsPerTxn;

  const SalesReportData({
    required this.groupBy,
    required this.rows,
    required this.transactions,
    required this.grossSales,
    required this.discounts,
    required this.netSales,
    required this.taxCollected,
    required this.revenue,
    required this.itemsPerTxn,
  });

  factory SalesReportData.fromMap(Map<String, dynamic> m) {
    final totals = Map<String, dynamic>.from((m['totals'] as Map?) ?? const {});
    return SalesReportData(
      groupBy: (m['group_by'] as String?) ?? 'day',
      rows: ((m['rows'] as List?) ?? const [])
          .map((r) => SalesReportRow.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
      transactions: _i(totals['transactions']),
      grossSales: _d(totals['gross_sales']),
      discounts: _d(totals['discounts']),
      netSales: _d(totals['net_sales']),
      taxCollected: _d(totals['tax_collected']),
      revenue: _d(totals['revenue']),
      itemsPerTxn: _d(totals['items_per_txn']),
    );
  }
}

// ---------------------------------------------------------------------------
// Profit report (§51)
// ---------------------------------------------------------------------------
class ProfitReportData {
  final Decimal revenue;
  final Decimal taxCollected;
  final Decimal cogs;
  final Decimal grossProfit;
  final Decimal refunds;
  final Decimal expenses;
  final Decimal operatingProfit;

  const ProfitReportData({
    required this.revenue,
    required this.taxCollected,
    required this.cogs,
    required this.grossProfit,
    required this.refunds,
    required this.expenses,
    required this.operatingProfit,
  });

  factory ProfitReportData.fromMap(Map<String, dynamic> m) => ProfitReportData(
        revenue: _d(m['revenue']),
        taxCollected: _d(m['tax_collected']),
        cogs: _d(m['cogs']),
        grossProfit: _d(m['gross_profit']),
        refunds: _d(m['refunds']),
        expenses: _d(m['expenses']),
        operatingProfit: _d(m['operating_profit']),
      );
}

// ---------------------------------------------------------------------------
// Inventory report (§52)
// ---------------------------------------------------------------------------
class DeadStockRow {
  final String productId;
  final String name;
  final Decimal onHand;
  final Decimal wac;
  final DateTime? lastSoldAt;

  const DeadStockRow({
    required this.productId,
    required this.name,
    required this.onHand,
    required this.wac,
    this.lastSoldAt,
  });

  factory DeadStockRow.fromMap(Map<String, dynamic> m) => DeadStockRow(
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        onHand: _d(m['on_hand']),
        wac: _d(m['wac']),
        lastSoldAt: m['last_sold_at'] == null ? null : _dt(m['last_sold_at']),
      );
}

class ExpiringBatchRow {
  final String batchId;
  final String productId;
  final String name;
  final String? batchNo;
  final DateTime? expiryDate;
  final Decimal qty;

  const ExpiringBatchRow({
    required this.batchId,
    required this.productId,
    required this.name,
    required this.qty,
    this.batchNo,
    this.expiryDate,
  });

  factory ExpiringBatchRow.fromMap(Map<String, dynamic> m) => ExpiringBatchRow(
        batchId: m['batch_id'] as String,
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        batchNo: m['batch_no'] as String?,
        expiryDate: m['expiry_date'] == null ? null : _dt(m['expiry_date']),
        qty: _d(m['qty']),
      );
}

/// Reorder suggestion (product spec §103 "reorder suggestions"): 90-day
/// average daily sales × a 7-day lead time, topped up to the reorder level.
class ReorderSuggestionRow {
  final String productId;
  final String name;
  final String? sku;
  final Decimal onHand;
  final Decimal reorderLevel;
  final Decimal avgDailySales;
  final Decimal suggestedQty;

  const ReorderSuggestionRow({
    required this.productId,
    required this.name,
    required this.onHand,
    required this.reorderLevel,
    required this.avgDailySales,
    required this.suggestedQty,
    this.sku,
  });

  factory ReorderSuggestionRow.fromMap(Map<String, dynamic> m) => ReorderSuggestionRow(
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        sku: m['sku'] as String?,
        onHand: _d(m['on_hand']),
        reorderLevel: _d(m['reorder_level']),
        avgDailySales: _d(m['avg_daily_sales']),
        suggestedQty: _d(m['suggested_qty']),
      );
}

class InventoryReportData {
  final Decimal valueAtCost;
  final Decimal valueAtRetail;
  final Decimal marginValue;
  final int lowStockCount;
  final int outOfStockCount;
  final List<DeadStockRow> deadStock;
  final List<ExpiringBatchRow> expiring;
  final List<ReorderSuggestionRow> reorderSuggestions;

  const InventoryReportData({
    required this.valueAtCost,
    required this.valueAtRetail,
    required this.marginValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.deadStock,
    required this.expiring,
    this.reorderSuggestions = const [],
  });

  factory InventoryReportData.fromMap(Map<String, dynamic> m) => InventoryReportData(
        valueAtCost: _d(m['value_at_cost']),
        valueAtRetail: _d(m['value_at_retail']),
        marginValue: _d(m['margin_value']),
        lowStockCount: _i(m['low_stock_count']),
        outOfStockCount: _i(m['out_of_stock_count']),
        deadStock: ((m['dead_stock'] as List?) ?? const [])
            .map((r) => DeadStockRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        expiring: ((m['expiring'] as List?) ?? const [])
            .map((r) => ExpiringBatchRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        reorderSuggestions: ((m['reorder_suggestions'] as List?) ?? const [])
            .map((r) => ReorderSuggestionRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Purchases report (§53)
// ---------------------------------------------------------------------------
class SupplierPurchaseRow {
  final String supplierId;
  final String name;
  final int bills;
  final Decimal total;

  const SupplierPurchaseRow({
    required this.supplierId,
    required this.name,
    required this.bills,
    required this.total,
  });

  factory SupplierPurchaseRow.fromMap(Map<String, dynamic> m) => SupplierPurchaseRow(
        supplierId: m['supplier_id'] as String,
        name: (m['name'] as String?) ?? '',
        bills: _i(m['bills']),
        total: _d(m['total']),
      );
}

class UnpaidBillRow {
  final String id;
  final String? billNumber;
  final String supplierName;
  final Decimal total;
  final Decimal paidTotal;
  final Decimal balance;
  final DateTime? dueAt;

  const UnpaidBillRow({
    required this.id,
    required this.supplierName,
    required this.total,
    required this.paidTotal,
    required this.balance,
    this.billNumber,
    this.dueAt,
  });

  factory UnpaidBillRow.fromMap(Map<String, dynamic> m) => UnpaidBillRow(
        id: m['id'] as String,
        billNumber: m['bill_number'] as String?,
        supplierName: (m['supplier_name'] as String?) ?? '',
        total: _d(m['total']),
        paidTotal: _d(m['paid_total']),
        balance: _d(m['balance']),
        dueAt: m['due_at'] == null ? null : _dt(m['due_at']),
      );
}

class SupplierAgeingRow {
  final String supplierId;
  final String name;
  final Decimal b0To30;
  final Decimal b30To60;
  final Decimal b60To90;
  final Decimal b90Plus;

  const SupplierAgeingRow({
    required this.supplierId,
    required this.name,
    required this.b0To30,
    required this.b30To60,
    required this.b60To90,
    required this.b90Plus,
  });

  factory SupplierAgeingRow.fromMap(Map<String, dynamic> m) => SupplierAgeingRow(
        supplierId: m['supplier_id'] as String,
        name: (m['name'] as String?) ?? '',
        b0To30: _d(m['bucket_0_30']),
        b30To60: _d(m['bucket_30_60']),
        b60To90: _d(m['bucket_60_90']),
        b90Plus: _d(m['bucket_90_plus']),
      );
}

class PurchasesReportData {
  final Decimal totalPurchases;
  final List<SupplierPurchaseRow> bySupplier;
  final List<UnpaidBillRow> unpaidBills;
  final List<SupplierAgeingRow> supplierAgeing;

  const PurchasesReportData({
    required this.totalPurchases,
    required this.bySupplier,
    required this.unpaidBills,
    required this.supplierAgeing,
  });

  factory PurchasesReportData.fromMap(Map<String, dynamic> m) => PurchasesReportData(
        totalPurchases: _d(m['total_purchases']),
        bySupplier: ((m['by_supplier'] as List?) ?? const [])
            .map((r) => SupplierPurchaseRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        unpaidBills: ((m['unpaid_bills'] as List?) ?? const [])
            .map((r) => UnpaidBillRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        supplierAgeing: ((m['supplier_ageing'] as List?) ?? const [])
            .map((r) => SupplierAgeingRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Cash report (§54)
// ---------------------------------------------------------------------------
class CashShiftRow {
  final String id;
  final DateTime openedAt;
  final DateTime? closedAt;
  final Decimal openingFloat;
  final Decimal? expectedCash;
  final Decimal? closingCounted;
  final Decimal? variance;
  final String status;
  final String? cashierName;
  final String? branchName;

  const CashShiftRow({
    required this.id,
    required this.openedAt,
    required this.openingFloat,
    required this.status,
    this.closedAt,
    this.expectedCash,
    this.closingCounted,
    this.variance,
    this.cashierName,
    this.branchName,
  });

  factory CashShiftRow.fromMap(Map<String, dynamic> m) => CashShiftRow(
        id: m['id'] as String,
        openedAt: _dt(m['opened_at']),
        closedAt: m['closed_at'] == null ? null : _dt(m['closed_at']),
        openingFloat: _d(m['opening_float']),
        expectedCash: m['expected_cash'] == null ? null : _d(m['expected_cash']),
        closingCounted: m['closing_counted'] == null ? null : _d(m['closing_counted']),
        variance: m['variance'] == null ? null : _d(m['variance']),
        status: (m['status'] as String?) ?? 'open',
        cashierName: m['cashier_name'] as String?,
        branchName: m['branch_name'] as String?,
      );
}

class CashVarianceRow {
  final String id;
  final DateTime openedAt;
  final Decimal variance;
  final String? varianceReason;
  final String? cashierName;

  const CashVarianceRow({
    required this.id,
    required this.openedAt,
    required this.variance,
    this.varianceReason,
    this.cashierName,
  });

  factory CashVarianceRow.fromMap(Map<String, dynamic> m) => CashVarianceRow(
        id: m['id'] as String,
        openedAt: _dt(m['opened_at']),
        variance: _d(m['variance']),
        varianceReason: m['variance_reason'] as String?,
        cashierName: m['cashier_name'] as String?,
      );
}

class CashierRow {
  final String? cashierId;
  final String? cashierName;
  final int transactions;
  final Decimal revenue;

  const CashierRow({
    required this.transactions,
    required this.revenue,
    this.cashierId,
    this.cashierName,
  });

  factory CashierRow.fromMap(Map<String, dynamic> m) => CashierRow(
        cashierId: m['cashier_id'] as String?,
        cashierName: m['cashier_name'] as String?,
        transactions: _i(m['transactions']),
        revenue: _d(m['revenue']),
      );
}

class CashReportData {
  final List<CashShiftRow> shifts;
  final List<CashVarianceRow> variances;
  final List<CashierRow> byCashier;

  const CashReportData({
    required this.shifts,
    required this.variances,
    required this.byCashier,
  });

  factory CashReportData.fromMap(Map<String, dynamic> m) => CashReportData(
        shifts: ((m['shifts'] as List?) ?? const [])
            .map((r) => CashShiftRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        variances: ((m['variances'] as List?) ?? const [])
            .map((r) => CashVarianceRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        byCashier: ((m['by_cashier'] as List?) ?? const [])
            .map((r) => CashierRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Costing report (§55)
// ---------------------------------------------------------------------------
class CostingProductRow {
  final String productId;
  final String name;
  final Decimal sellingPrice;
  final Decimal wac;
  final Decimal onHand;
  final Decimal marginPct;
  final Decimal potentialProfit;

  const CostingProductRow({
    required this.productId,
    required this.name,
    required this.sellingPrice,
    required this.wac,
    required this.onHand,
    required this.marginPct,
    required this.potentialProfit,
  });

  factory CostingProductRow.fromMap(Map<String, dynamic> m) => CostingProductRow(
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        sellingPrice: _d(m['selling_price']),
        wac: _d(m['wac']),
        onHand: _d(m['on_hand']),
        marginPct: _d(m['margin_pct']),
        potentialProfit: _d(m['potential_profit']),
      );
}

class PriceHistoryRow {
  final String productId;
  final String name;
  final Decimal oldPurchasePrice;
  final Decimal newPurchasePrice;
  final Decimal oldSellingPrice;
  final Decimal newSellingPrice;
  final DateTime createdAt;

  const PriceHistoryRow({
    required this.productId,
    required this.name,
    required this.oldPurchasePrice,
    required this.newPurchasePrice,
    required this.oldSellingPrice,
    required this.newSellingPrice,
    required this.createdAt,
  });

  factory PriceHistoryRow.fromMap(Map<String, dynamic> m) => PriceHistoryRow(
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        oldPurchasePrice: _d(m['old_purchase_price']),
        newPurchasePrice: _d(m['new_purchase_price']),
        oldSellingPrice: _d(m['old_selling_price']),
        newSellingPrice: _d(m['new_selling_price']),
        createdAt: _dt(m['created_at']),
      );
}

class CostingReportData {
  final List<CostingProductRow> products;
  final List<PriceHistoryRow> priceHistory;

  const CostingReportData({required this.products, required this.priceHistory});

  factory CostingReportData.fromMap(Map<String, dynamic> m) => CostingReportData(
        products: ((m['products'] as List?) ?? const [])
            .map((r) => CostingProductRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        priceHistory: ((m['price_history'] as List?) ?? const [])
            .map((r) => PriceHistoryRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Expense report (product spec §49 "Expense report")
// ---------------------------------------------------------------------------
class ExpenseReportTotals {
  final int count;
  final Decimal total;
  final Decimal avg;

  const ExpenseReportTotals({
    required this.count,
    required this.total,
    required this.avg,
  });

  factory ExpenseReportTotals.fromMap(Map<String, dynamic> m) => ExpenseReportTotals(
        count: _i(m['count']),
        total: _d(m['total']),
        avg: _d(m['avg']),
      );
}

class ExpenseCategoryRow {
  final String category;
  final int entries;
  final Decimal amount;

  const ExpenseCategoryRow({
    required this.category,
    required this.entries,
    required this.amount,
  });

  factory ExpenseCategoryRow.fromMap(Map<String, dynamic> m) => ExpenseCategoryRow(
        category: (m['category'] as String?) ?? '',
        entries: _i(m['entries']),
        amount: _d(m['amount']),
      );
}

class MethodAmountRow {
  final String method;
  final Decimal amount;
  final int entries;

  const MethodAmountRow({required this.method, required this.amount, required this.entries});

  factory MethodAmountRow.fromMap(Map<String, dynamic> m) => MethodAmountRow(
        method: (m['method'] as String?) ?? '',
        amount: _d(m['amount']),
        entries: _i(m['entries']),
      );
}

class DayAmountRow {
  final DateTime day;
  final Decimal amount;
  final int entries;

  const DayAmountRow({required this.day, required this.amount, required this.entries});

  factory DayAmountRow.fromMap(Map<String, dynamic> m) => DayAmountRow(
        day: _dt(m['day']),
        amount: _d(m['amount']),
        entries: _i(m['entries']),
      );
}

class ExpensesReportData {
  final ExpenseReportTotals totals;
  final List<ExpenseCategoryRow> byCategory;
  final List<MethodAmountRow> byPaymentMethod;
  final List<DayAmountRow> byDay;

  const ExpensesReportData({
    required this.totals,
    required this.byCategory,
    required this.byPaymentMethod,
    required this.byDay,
  });

  factory ExpensesReportData.fromMap(Map<String, dynamic> m) => ExpensesReportData(
        totals: ExpenseReportTotals.fromMap(
          Map<String, dynamic>.from((m['totals'] as Map?) ?? const {}),
        ),
        byCategory: ((m['by_category'] as List?) ?? const [])
            .map((r) => ExpenseCategoryRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        byPaymentMethod: ((m['by_payment_method'] as List?) ?? const [])
            .map((r) => MethodAmountRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
        byDay: ((m['by_day'] as List?) ?? const [])
            .map((r) => DayAmountRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Supplier report (product spec §49 "Supplier report", §27)
// ---------------------------------------------------------------------------
class SupplierReportRow {
  final String supplierId;
  final String name;
  final String? phone;
  final Decimal purchasesTotal;
  final int purchasesCount;
  final Decimal paidTotal;
  final Decimal balanceDue;

  const SupplierReportRow({
    required this.supplierId,
    required this.name,
    required this.purchasesTotal,
    required this.purchasesCount,
    required this.paidTotal,
    required this.balanceDue,
    this.phone,
  });

  factory SupplierReportRow.fromMap(Map<String, dynamic> m) => SupplierReportRow(
        supplierId: m['supplier_id'] as String,
        name: (m['name'] as String?) ?? '',
        phone: m['phone'] as String?,
        purchasesTotal: _d(m['purchases_total']),
        purchasesCount: _i(m['purchases_count']),
        paidTotal: _d(m['paid_total']),
        balanceDue: _d(m['balance_due']),
      );
}

class SupplierReportTotals {
  final int suppliers;
  final Decimal purchases;
  final Decimal paid;
  final Decimal balanceDue;

  const SupplierReportTotals({
    required this.suppliers,
    required this.purchases,
    required this.paid,
    required this.balanceDue,
  });

  factory SupplierReportTotals.fromMap(Map<String, dynamic> m) => SupplierReportTotals(
        suppliers: _i(m['suppliers']),
        purchases: _d(m['purchases']),
        paid: _d(m['paid']),
        balanceDue: _d(m['balance_due']),
      );
}

class SuppliersReportData {
  final SupplierReportTotals totals;
  final List<SupplierReportRow> rows;

  const SuppliersReportData({required this.totals, required this.rows});

  factory SuppliersReportData.fromMap(Map<String, dynamic> m) => SuppliersReportData(
        totals: SupplierReportTotals.fromMap(
          Map<String, dynamic>.from((m['totals'] as Map?) ?? const {}),
        ),
        rows: ((m['rows'] as List?) ?? const [])
            .map((r) => SupplierReportRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Customer report (product spec §49 "Customer report")
// ---------------------------------------------------------------------------
class CustomerReportRow {
  final String customerId;
  final String name;
  final String? phone;
  final Decimal loyaltyPoints;
  final int invoices;
  final Decimal revenue;
  final Decimal outstanding;

  const CustomerReportRow({
    required this.customerId,
    required this.name,
    required this.loyaltyPoints,
    required this.invoices,
    required this.revenue,
    required this.outstanding,
    this.phone,
  });

  factory CustomerReportRow.fromMap(Map<String, dynamic> m) => CustomerReportRow(
        customerId: m['customer_id'] as String,
        name: (m['name'] as String?) ?? '',
        phone: m['phone'] as String?,
        loyaltyPoints: _d(m['loyalty_points']),
        invoices: _i(m['invoices']),
        revenue: _d(m['revenue']),
        outstanding: _d(m['outstanding']),
      );
}

class CustomerReportTotals {
  final int customers;
  final int invoices;
  final Decimal revenue;
  final Decimal loyaltyPoints;

  const CustomerReportTotals({
    required this.customers,
    required this.invoices,
    required this.revenue,
    required this.loyaltyPoints,
  });

  factory CustomerReportTotals.fromMap(Map<String, dynamic> m) => CustomerReportTotals(
        customers: _i(m['customers']),
        invoices: _i(m['invoices']),
        revenue: _d(m['revenue']),
        loyaltyPoints: _d(m['loyalty_points']),
      );
}

class CustomersReportData {
  final CustomerReportTotals totals;
  final List<CustomerReportRow> rows;

  const CustomersReportData({required this.totals, required this.rows});

  factory CustomersReportData.fromMap(Map<String, dynamic> m) => CustomersReportData(
        totals: CustomerReportTotals.fromMap(
          Map<String, dynamic>.from((m['totals'] as Map?) ?? const {}),
        ),
        rows: ((m['rows'] as List?) ?? const [])
            .map((r) => CustomerReportRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}

// ---------------------------------------------------------------------------
// Product performance (product spec §52, §53 best sellers)
// ---------------------------------------------------------------------------
class ProductPerformanceRow {
  final String productId;
  final String name;
  final String? sku;
  final Decimal sellingPrice;
  final Decimal qtySold;
  final Decimal revenue;
  final Decimal cost;
  final Decimal profit;
  final Decimal marginPct;
  final Decimal onHand;

  const ProductPerformanceRow({
    required this.productId,
    required this.name,
    required this.sellingPrice,
    required this.qtySold,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.marginPct,
    required this.onHand,
    this.sku,
  });

  factory ProductPerformanceRow.fromMap(Map<String, dynamic> m) => ProductPerformanceRow(
        productId: m['product_id'] as String,
        name: (m['name'] as String?) ?? '',
        sku: m['sku'] as String?,
        sellingPrice: _d(m['selling_price']),
        qtySold: _d(m['qty_sold']),
        revenue: _d(m['revenue']),
        cost: _d(m['cost']),
        profit: _d(m['profit']),
        marginPct: _d(m['margin_pct']),
        onHand: _d(m['on_hand']),
      );
}

class ProductReportTotals {
  final Decimal revenue;
  final Decimal cost;
  final Decimal qtySold;

  const ProductReportTotals({
    required this.revenue,
    required this.cost,
    required this.qtySold,
  });

  factory ProductReportTotals.fromMap(Map<String, dynamic> m) => ProductReportTotals(
        revenue: _d(m['revenue']),
        cost: _d(m['cost']),
        qtySold: _d(m['qty_sold']),
      );
}

class ProductsReportData {
  final ProductReportTotals totals;
  final List<ProductPerformanceRow> rows;

  const ProductsReportData({required this.totals, required this.rows});

  factory ProductsReportData.fromMap(Map<String, dynamic> m) => ProductsReportData(
        totals: ProductReportTotals.fromMap(
          Map<String, dynamic>.from((m['totals'] as Map?) ?? const {}),
        ),
        rows: ((m['rows'] as List?) ?? const [])
            .map((r) => ProductPerformanceRow.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList(),
      );
}
