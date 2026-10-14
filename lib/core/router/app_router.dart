import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit/screens/audit_log_screen.dart';
import '../../core/access/access_policy.dart';
import '../../features/auth/providers/permissions_controller.dart';
import '../../features/auth/providers/session_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/branches/screens/branch_form_screen.dart';
import '../../features/branches/screens/branch_list_screen.dart';
import '../../features/branches/screens/terminal_form_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/expenses/screens/expense_categories_screen.dart';
import '../../features/expenses/screens/expense_form_screen.dart';
import '../../features/expenses/screens/expense_list_screen.dart';
import '../../features/import_export/screens/import_export_screen.dart';
import '../../features/inventory/screens/batch_expiry_screen.dart';
import '../../features/inventory/screens/inventory_list_screen.dart';
import '../../features/inventory/screens/stock_adjustment_screen.dart';
import '../../features/inventory/screens/stock_count_entry_screen.dart';
import '../../features/inventory/screens/stock_count_list_screen.dart';
import '../../features/inventory/screens/stock_detail_screen.dart';
import '../../features/inventory/screens/transfer_form_screen.dart';
import '../../features/inventory/screens/transfer_list_screen.dart';
import '../../features/more/screens/more_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/parties/screens/customer_detail_screen.dart';
import '../../features/parties/screens/customer_form_screen.dart';
import '../../features/parties/screens/customer_list_screen.dart';
import '../../features/parties/screens/supplier_detail_screen.dart';
import '../../features/parties/screens/supplier_form_screen.dart';
import '../../features/parties/screens/supplier_list_screen.dart';
import '../../features/pos/screens/camera_scanner_screen.dart';
import '../../features/pos/screens/customer_picker_screen.dart';
import '../../features/pos/screens/held_carts_screen.dart';
import '../../features/pos/screens/payment_screen.dart';
import '../../features/pos/screens/pos_screen.dart';
import '../../features/pos/screens/return_form_screen.dart';
import '../../features/pos/screens/sale_detail_screen.dart';
import '../../features/pos/screens/sales_history_screen.dart';
import '../../features/platform/screens/businesses_screen.dart';
import '../../features/products/screens/brand_list_screen.dart';
import '../../features/products/screens/category_list_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/product_list_screen.dart';
import '../../features/products/screens/taxonomy_form_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/promotions/screens/promotion_form_screen.dart';
import '../../features/promotions/screens/promotion_list_screen.dart';
import '../../features/purchasing/screens/goods_receive_screen.dart';
import '../../features/purchasing/screens/purchase_bill_list_screen.dart';
import '../../features/purchasing/screens/purchase_order_detail_screen.dart';
import '../../features/purchasing/screens/purchase_order_form_screen.dart';
import '../../features/purchasing/screens/purchase_order_list_screen.dart';
import '../../features/reports/screens/cash_report_screen.dart';
import '../../features/reports/screens/costing_report_screen.dart';
import '../../features/reports/screens/customers_report_screen.dart';
import '../../features/reports/screens/expenses_report_screen.dart';
import '../../features/reports/screens/products_report_screen.dart';
import '../../features/reports/screens/suppliers_report_screen.dart';
import '../../features/reports/screens/inventory_report_screen.dart';
import '../../features/reports/screens/profit_report_screen.dart';
import '../../features/reports/screens/purchases_report_screen.dart';
import '../../features/reports/screens/reports_hub_screen.dart';
import '../../features/reports/screens/sales_report_screen.dart';
import '../../features/search/screens/global_search_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/sync/screens/sync_queue_screen.dart';
import '../../features/shifts/screens/cash_drawer_screen.dart';
import '../../features/shifts/screens/shift_close_screen.dart';
import '../../features/shifts/screens/shift_list_screen.dart';
import '../../features/shifts/screens/shift_open_screen.dart';
import '../../features/team/screens/team_screen.dart';
import '../../features/setup/screens/business_setup_screen.dart';

/// Central route table. Paths are stable strings so navigation never
/// string-interpolates ad hoc (SPEC §85).
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const setup = '/setup';

  static const dashboard = '/app/dashboard';
  static const more = '/app/more';
  static const search = '/app/search';
  static const notifications = '/app/notifications';
  static const syncStatus = '/app/sync';
  static const profile = '/app/profile';

  static const products = '/app/products';
  static const productNew = '/app/products/new';
  static const productView = '/app/products/view';
  static const categories = '/app/categories';
  static const categoryNew = '/app/categories/new';
  static const categoryEdit = '/app/categories';
  static const brands = '/app/brands';
  static const brandNew = '/app/brands/new';
  static const brandEdit = '/app/brands';

  static const inventory = '/app/inventory';
  static const stockProduct = '/app/inventory/product';
  static const stockAdjust = '/app/inventory/adjust';
  static const stockCounts = '/app/inventory/counts';
  static const stockCountEntry = '/app/inventory/counts/entry';
  static const stockTransfers = '/app/inventory/transfers';
  static const stockTransferNew = '/app/inventory/transfers/new';
  static const batches = '/app/inventory/batches';

  static const suppliers = '/app/suppliers';
  static const supplierNew = '/app/suppliers/new';
  static const customers = '/app/customers';
  static const customerNew = '/app/customers/new';

  static const purchaseOrders = '/app/purchase-orders';
  static const purchaseOrderNew = '/app/purchase-orders/new';
  static const purchaseBills = '/app/purchase-bills';

  static const expenses = '/app/expenses';
  static const expenseNew = '/app/expenses/new';
  static const expenseCategories = '/app/expenses/categories';

  static const promotions = '/app/promotions';
  static const promotionNew = '/app/promotions/new';

  static const reports = '/app/reports';
  static const reportSales = '/app/reports/sales';
  static const reportProfit = '/app/reports/profit';
  static const reportInventory = '/app/reports/inventory';
  static const reportPurchases = '/app/reports/purchases';
  static const reportCash = '/app/reports/cash';
  static const reportCosting = '/app/reports/costing';
  static const reportExpenses = '/app/reports/expenses';
  static const reportSuppliers = '/app/reports/suppliers';
  static const reportCustomers = '/app/reports/customers';
  static const reportProducts = '/app/reports/products';

  static const team = '/app/team';
  static const audit = '/app/audit';
  static const importExport = '/app/import-export';

  static const branches = '/app/branches';
  static const businesses = '/app/businesses';
  static const branchNew = '/app/branches/new';
  static const terminals = '/app/terminals';
  static const terminalNew = '/app/terminals/new';

  static const pos = '/app/pos';
  static const posPayment = '/pos/payment';
  static const posHeld = '/pos/held';
  static const posCustomers = '/pos/customers';
  static const posCamera = '/pos/camera';
  static const sales = '/app/sales';
  static const saleDetail = '/sales';
  static const shifts = '/app/shifts';
  static const shiftNew = '/app/shifts/new';
  static const shiftClose = '/app/shifts/close';
  static const cashDrawer = '/app/shifts/cash';
  static const settings = '/app/settings';
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    // Re-evaluate redirects whenever the session moves between
    // loading / signedOut / needsBusiness / ready.
    ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    // ...and whenever the role's permission keys arrive (role-based UI, §87).
    ref.listen(permissionsProvider, (_, _) => notifyListeners());
  }
}

/// Post-login destination for the current role (SPEC §87): the first landing
/// candidate the role may open — a cashier lands on the POS, a stocker on
/// inventory, an owner/manager on the dashboard.
String _landing(Ref ref) {
  final session = ref.read(sessionControllerProvider);
  // A platform super admin without a business lands on the platform console
  // (SPEC §3.1) — the dashboard belongs to a business, they have none.
  if (session.isSuperAdmin && session.profile?.businessId == null) {
    return AppRoutes.businesses;
  }
  final access = ref.read(permissionsProvider).valueOrNull ??
      const AccessPolicy.allowAll();
  return access.firstAllowed;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final status = ref.read(sessionControllerProvider).status;
      final location = state.matchedLocation;
      final onAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.forgotPassword ||
          location == AppRoutes.otp;

      switch (status) {
        case AppStatus.loading:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AppStatus.signedOut:
          return onAuthRoute ? null : AppRoutes.login;
        case AppStatus.deactivated:
          // Deactivated accounts stay on the sign-in screen, where the login
          // form shows the "account deactivated" notice (SPEC §66).
          return location == AppRoutes.login ? null : AppRoutes.login;
        case AppStatus.needsBusiness:
          return location == AppRoutes.setup ? null : AppRoutes.setup;
        case AppStatus.ready:
          if (location == AppRoutes.splash || onAuthRoute || location == AppRoutes.setup) {
            return _landing(ref);
          }
          // Role-based navigation (SPEC §3, §87): a role that may not open the
          // requested module is sent to the first module it can open instead.
          final access = ref.read(permissionsProvider).valueOrNull ??
              const AccessPolicy.allowAll();
          if (!access.canOpen(location)) return access.redirectFor(location);
          return null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: AppRoutes.login,
        // `extra` carries an email address to prefill (sign-up → sign-in hand-off).
        builder: (_, state) => LoginScreen(initialEmail: state.extra as String?),
      ),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, _) => const ForgotPasswordScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, state) => OtpScreen(email: (state.extra as String?) ?? ''),
      ),
      GoRoute(path: AppRoutes.setup, builder: (_, _) => const BusinessSetupScreen()),

      // Full-screen flows outside the shell.
      GoRoute(path: AppRoutes.posPayment, builder: (_, _) => const PaymentScreen()),
      GoRoute(path: AppRoutes.posHeld, builder: (_, _) => const HeldCartsScreen()),
      GoRoute(path: AppRoutes.posCustomers, builder: (_, _) => const CustomerPickerScreen()),
      GoRoute(path: AppRoutes.posCamera, builder: (_, _) => const CameraScannerScreen()),
      GoRoute(
        path: '${AppRoutes.saleDetail}/:id',
        builder: (_, state) => SaleDetailScreen(saleId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.saleDetail}/:id/return',
        builder: (_, state) => ReturnFormScreen(saleId: state.pathParameters['id']!),
      ),

      ShellRoute(
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: AppRoutes.dashboard, builder: (_, _) => const DashboardScreen()),
          GoRoute(path: AppRoutes.pos, builder: (_, _) => const PosScreen()),
          GoRoute(path: AppRoutes.sales, builder: (_, _) => const SalesHistoryScreen()),
          GoRoute(path: AppRoutes.more, builder: (_, _) => const MoreScreen()),
          GoRoute(path: AppRoutes.search, builder: (_, _) => const GlobalSearchScreen()),
          GoRoute(path: AppRoutes.notifications, builder: (_, _) => const NotificationsScreen()),
          GoRoute(path: AppRoutes.syncStatus, builder: (_, _) => const SyncQueueScreen()),
          GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),

          // Catalog
          GoRoute(path: AppRoutes.products, builder: (_, _) => const ProductListScreen()),
          GoRoute(path: AppRoutes.productNew, builder: (_, _) => const ProductFormScreen()),
          GoRoute(
            path: '${AppRoutes.productView}/:id',
            builder: (_, state) => ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.products}/:id',
            builder: (_, state) => ProductFormScreen(productId: state.pathParameters['id']),
          ),
          GoRoute(path: AppRoutes.categories, builder: (_, _) => const CategoryListScreen()),
          GoRoute(
            path: AppRoutes.categoryNew,
            builder: (_, _) => const TaxonomyFormScreen(kind: TaxonomyKind.category),
          ),
          GoRoute(
            path: '${AppRoutes.categoryEdit}/:id',
            builder: (_, state) => TaxonomyFormScreen(
              kind: TaxonomyKind.category,
              id: state.pathParameters['id'],
            ),
          ),
          GoRoute(path: AppRoutes.brands, builder: (_, _) => const BrandListScreen()),
          GoRoute(
            path: AppRoutes.brandNew,
            builder: (_, _) => const TaxonomyFormScreen(kind: TaxonomyKind.brand),
          ),
          GoRoute(
            path: '${AppRoutes.brandEdit}/:id',
            builder: (_, state) => TaxonomyFormScreen(
              kind: TaxonomyKind.brand,
              id: state.pathParameters['id'],
            ),
          ),

          // Inventory
          GoRoute(path: AppRoutes.inventory, builder: (_, _) => const InventoryListScreen()),
          GoRoute(
            path: '${AppRoutes.stockProduct}/:id',
            builder: (_, state) => StockDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.stockAdjust}/:id',
            builder: (_, state) => StockAdjustmentScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.stockCounts, builder: (_, _) => const StockCountListScreen()),
          GoRoute(
            path: '${AppRoutes.stockCountEntry}/:id',
            builder: (_, state) =>
                StockCountEntryScreen(stockCountId: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.stockTransfers, builder: (_, _) => const TransferListScreen()),
          GoRoute(path: AppRoutes.stockTransferNew, builder: (_, _) => const TransferFormScreen()),
          GoRoute(path: AppRoutes.batches, builder: (_, _) => const BatchExpiryScreen()),

          // Parties
          GoRoute(path: AppRoutes.suppliers, builder: (_, _) => const SupplierListScreen()),
          GoRoute(path: AppRoutes.supplierNew, builder: (_, _) => const SupplierFormScreen()),
          GoRoute(
            path: '${AppRoutes.suppliers}/:id',
            builder: (_, state) => SupplierDetailScreen(supplierId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.suppliers}/:id/edit',
            builder: (_, state) =>
                SupplierFormScreen(supplierId: state.pathParameters['id']),
          ),
          GoRoute(path: AppRoutes.customers, builder: (_, _) => const CustomerListScreen()),
          GoRoute(path: AppRoutes.customerNew, builder: (_, _) => const CustomerFormScreen()),
          GoRoute(
            path: '${AppRoutes.customers}/:id',
            builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.customers}/:id/edit',
            builder: (_, state) =>
                CustomerFormScreen(customerId: state.pathParameters['id']),
          ),

          // Purchasing
          GoRoute(path: AppRoutes.purchaseOrders, builder: (_, _) => const PurchaseOrderListScreen()),
          GoRoute(
            path: AppRoutes.purchaseOrderNew,
            builder: (_, _) => const PurchaseOrderFormScreen(),
          ),
          GoRoute(path: AppRoutes.purchaseBills, builder: (_, _) => const PurchaseBillListScreen()),
          GoRoute(
            path: '${AppRoutes.purchaseOrders}/:id/receive',
            builder: (_, state) =>
                GoodsReceiveScreen(purchaseOrderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.purchaseOrders}/:id',
            builder: (_, state) =>
                PurchaseOrderDetailScreen(purchaseOrderId: state.pathParameters['id']!),
          ),

          // Finance & marketing
          GoRoute(path: AppRoutes.expenses, builder: (_, _) => const ExpenseListScreen()),
          GoRoute(path: AppRoutes.expenseNew, builder: (_, _) => const ExpenseFormScreen()),
          GoRoute(
            path: AppRoutes.expenseCategories,
            builder: (_, _) => const ExpenseCategoriesScreen(),
          ),
          GoRoute(
            path: '${AppRoutes.expenses}/:id/edit',
            builder: (_, state) => ExpenseFormScreen(expenseId: state.pathParameters['id']),
          ),
          GoRoute(path: AppRoutes.promotions, builder: (_, _) => const PromotionListScreen()),
          GoRoute(path: AppRoutes.promotionNew, builder: (_, _) => const PromotionFormScreen()),
          GoRoute(
            path: '${AppRoutes.promotions}/:id/edit',
            builder: (_, state) => PromotionFormScreen(promotionId: state.pathParameters['id']),
          ),

          // Reports
          GoRoute(path: AppRoutes.reports, builder: (_, _) => const ReportsHubScreen()),
          GoRoute(path: AppRoutes.reportSales, builder: (_, _) => const SalesReportScreen()),
          GoRoute(path: AppRoutes.reportProfit, builder: (_, _) => const ProfitReportScreen()),
          GoRoute(path: AppRoutes.reportInventory, builder: (_, _) => const InventoryReportScreen()),
          GoRoute(path: AppRoutes.reportPurchases, builder: (_, _) => const PurchasesReportScreen()),
          GoRoute(path: AppRoutes.reportCash, builder: (_, _) => const CashReportScreen()),
          GoRoute(path: AppRoutes.reportCosting, builder: (_, _) => const CostingReportScreen()),
          GoRoute(path: AppRoutes.reportExpenses, builder: (_, _) => const ExpensesReportScreen()),
          GoRoute(path: AppRoutes.reportSuppliers, builder: (_, _) => const SuppliersReportScreen()),
          GoRoute(path: AppRoutes.reportCustomers, builder: (_, _) => const CustomersReportScreen()),
          GoRoute(path: AppRoutes.reportProducts, builder: (_, _) => const ProductsReportScreen()),

          // Admin
          GoRoute(path: AppRoutes.team, builder: (_, _) => const TeamScreen()),
          GoRoute(path: AppRoutes.audit, builder: (_, _) => const AuditLogScreen()),
          GoRoute(path: AppRoutes.importExport, builder: (_, _) => const ImportExportScreen()),

          // Branches & POS terminals (static paths before the `:id` forms)
          GoRoute(path: AppRoutes.branches, builder: (_, _) => const BranchListScreen()),
          GoRoute(path: AppRoutes.businesses, builder: (_, _) => const BusinessesScreen()),
          GoRoute(path: AppRoutes.branchNew, builder: (_, _) => const BranchFormScreen()),
          GoRoute(
            path: '${AppRoutes.branches}/:id',
            builder: (_, state) => BranchFormScreen(id: state.pathParameters['id']),
          ),
          GoRoute(path: AppRoutes.terminals, builder: (_, _) => const BranchListScreen()),
          GoRoute(path: AppRoutes.terminalNew, builder: (_, _) => const TerminalFormScreen()),
          GoRoute(
            path: '${AppRoutes.terminals}/:id',
            builder: (_, state) => TerminalFormScreen(id: state.pathParameters['id']),
          ),

          // Shifts & settings
          GoRoute(path: AppRoutes.shifts, builder: (_, _) => const ShiftListScreen()),
          GoRoute(path: AppRoutes.shiftNew, builder: (_, _) => const ShiftOpenScreen()),
          GoRoute(
            path: '${AppRoutes.shiftClose}/:id',
            builder: (_, state) => ShiftCloseScreen(shiftId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '${AppRoutes.cashDrawer}/:id',
            builder: (_, state) => CashDrawerScreen(shiftId: state.pathParameters['id']!),
          ),
          GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
