// Live data-layer smoke test.
//
// Drives the app's real repositories against the linked Supabase project with
// dummy data, so schema/model drift and PostgREST query bugs surface here rather
// than on a device.
//
// Skipped by default (keeps `flutter test` offline and write-free). Run
// explicitly after seeding a throwaway QA account:
//
//   1. create a confirmed auth user (see the seed SQL used for this run), give
//      it a business via public.create_business_with_owner, add a product with
//      barcode 2000000000015 / sku QA-COLA-1, a customer and a supplier, adjust
//      stock in and open a shift;
//   2. flutter test test/live/live_data_smoke_test.dart --dart-define=LIVE=true
//
// Credentials default to that QA user and can be overridden with
// --dart-define=QA_EMAIL=... --dart-define=QA_PASSWORD=...
//
// The suite is a diagnostic: it reads every repository and round-trips one sale
// against the linked project. It never runs as part of the normal test gate.
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supermarket_pos/core/config/app_config.dart';
import 'package:supermarket_pos/data/repositories/audit_repository.dart';
import 'package:supermarket_pos/data/repositories/business_repository.dart';
import 'package:supermarket_pos/data/repositories/catalog_repository.dart';
import 'package:supermarket_pos/data/repositories/expense_repository.dart';
import 'package:supermarket_pos/data/repositories/inventory_repository.dart';
import 'package:supermarket_pos/data/repositories/notification_repository.dart';
import 'package:supermarket_pos/data/repositories/parties_repository.dart';
import 'package:supermarket_pos/data/repositories/pos_repository.dart';
import 'package:supermarket_pos/data/repositories/product_repository.dart';
import 'package:supermarket_pos/data/repositories/profile_repository.dart';
import 'package:supermarket_pos/data/repositories/promotion_repository.dart';
import 'package:supermarket_pos/data/repositories/purchasing_repository.dart';
import 'package:supermarket_pos/data/repositories/reports_repository.dart';
import 'package:supermarket_pos/data/repositories/shift_repository.dart';

const _live = bool.fromEnvironment('LIVE');
const _email = String.fromEnvironment('QA_EMAIL', defaultValue: 'qa-bot@test.local');
const _password = String.fromEnvironment('QA_PASSWORD', defaultValue: 'QaBot!Pass123');

void main() {
  // Run against the real network: the Flutter test binding would otherwise
  // stub every HTTP call with a 400. We construct the client directly (rather
  // than Supabase.initialize) so no platform plugins are required.
  HttpOverrides.global = null;

  test(
    'live repository smoke (every read path + a sale round-trip)',
    () async {
      final client = SupabaseClient(
        AppConfig.supabaseUrl,
        AppConfig.supabaseAnonKey,
      );
      await client.auth.signInWithPassword(email: _email, password: _password);
      expect(client.auth.currentSession, isNotNull, reason: 'sign-in failed');

      final profileRepo = ProfileRepository(client);
      final businessRepo = BusinessRepository(client);
      final catalogRepo = CatalogRepository(client);
      final productRepo = ProductRepository(client);
      final inventoryRepo = InventoryRepository(client);
      final posRepo = PosRepository(client);
      final shiftRepo = ShiftRepository(client);
      final partiesRepo = PartiesRepository(client);
      final purchasingRepo = PurchasingRepository(client);
      final expenseRepo = ExpenseRepository(client);
      final promotionRepo = PromotionRepository(client);
      final notificationRepo = NotificationRepository(client);
      final auditRepo = AuditRepository(client);
      final reportsRepo = ReportsRepository(client);

      final profile = await profileRepo.fetchMyProfile();
      expect(profile, isNotNull, reason: 'profile');
      final businessId = profile!.businessId;
      if (businessId == null) {
        markTestSkipped('QA account has no business; seed it first (see file header)');
        return;
      }

      final business = await businessRepo.fetchById(businessId);
      expect(business, isNotNull, reason: 'business read');
      final branches = await businessRepo.fetchBranches(businessId);
      expect(branches, isNotEmpty, reason: 'branches');
      final branchId = branches.first.id;

      // Catalogue.
      expect(await catalogRepo.fetchCategories(), isNotEmpty);
      expect(await catalogRepo.fetchBrands(), isNotEmpty);
      expect(await catalogRepo.fetchUnits(), isNotEmpty);

      final page = await productRepo.fetchPage();
      expect(page, isNotEmpty, reason: 'products page');
      final product = page.first;
      expect(await productRepo.fetchById(product.id), isNotNull);
      final full = await productRepo.fetchFullById(product.id);
      expect(full, isNotNull, reason: 'product detail (cost view)');
      expect(await productRepo.fetchByBarcode('2000000000015'), isNotNull,
          reason: 'barcode lookup');
      expect(await productRepo.fetchBySku('QA-COLA-1'), isNotNull, reason: 'sku lookup');

      // Inventory.
      final onHand = await inventoryRepo.fetchOnHand();
      expect(onHand, isNotEmpty, reason: 'inventory_view read');
      expect(await inventoryRepo.fetchOnHandForProduct(product.id), isNotNull);
      expect(await inventoryRepo.fetchMovements(product.id), isNotEmpty);
      await inventoryRepo.fetchCounts();
      await inventoryRepo.fetchTransfers();
      await inventoryRepo.fetchBatches();

      // Parties.
      final suppliers = await partiesRepo.fetchSuppliers();
      expect(suppliers, isNotEmpty, reason: 'suppliers');
      expect(await partiesRepo.fetchSupplier(suppliers.first.id), isNotNull);
      final customers = await partiesRepo.fetchCustomers();
      expect(customers, isNotEmpty, reason: 'customers');
      final customer = customers.first;
      expect(await partiesRepo.fetchCustomer(customer.id), isNotNull);
      await partiesRepo.fetchLoyaltyTransactions(customer.id);
      await partiesRepo.fetchSupplierPayments(suppliers.first.id);

      // Shifts + cash.
      final shifts = await shiftRepo.fetchShifts();
      expect(shifts, isNotEmpty, reason: 'shifts');
      final openShift = shifts.firstWhere((s) => s.status == 'open');
      await shiftRepo.fetchCashMovements(openShift.id);

      // POS: complete a sale end-to-end through the real RPC, then read it back.
      final result = await posRepo.completeSale(
        branchId: branchId,
        shiftId: openShift.id,
        idempotencyKey: 'live-smoke-${DateTime.now().microsecondsSinceEpoch}',
        items: [
          {'product_id': product.id, 'qty': 2},
        ],
        payments: [
          {'method': 'cash', 'amount': 200},
        ],
        customerId: customer.id,
      );
      expect(result.grandTotal, Decimal.parse('200'));
      expect(result.invoiceNumber, isNotEmpty);

      final sale = await posRepo.fetchSale(result.saleId);
      expect(sale, isNotNull, reason: 'sale read-back');
      expect(sale!.status, 'completed');
      final items = await posRepo.fetchSaleItems(result.saleId);
      expect(items, hasLength(1));
      expect(items.first.qty, Decimal.parse('2'));
      expect(items.first.nameSnapshot, isNotEmpty, reason: 'line snapshot name');
      final payments = await posRepo.fetchSalePayments(result.saleId);
      expect(payments, isNotEmpty);
      final returned = await posRepo.fetchReturnedQuantities(result.saleId);
      expect(returned, isEmpty, reason: 'nothing returned yet');
      final history = await posRepo.fetchSales();
      expect(history.map((s) => s.id), contains(result.saleId));
      expect(await posRepo.searchCustomers(query: 'QA'), isNotEmpty);

      // Cancel it so the sale does not linger (stock is restored by the RPC).
      await posRepo.cancelSale(saleId: result.saleId, reason: 'live smoke cleanup');
      expect((await posRepo.fetchSale(result.saleId))!.status, 'cancelled');

      // Purchasing, expenses, promotions, notifications, audit, reports.
      await purchasingRepo.fetchPurchaseOrders();
      await purchasingRepo.fetchPurchases();
      await expenseRepo.fetchExpenses();
      await expenseRepo.fetchCategories();
      await promotionRepo.fetchPromotions();
      await notificationRepo.fetchPage();
      await notificationRepo.unreadCount();
      await auditRepo.fetchPage();

      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      await reportsRepo.sales(from: from, to: now);
      await reportsRepo.profit(from: from, to: now);
      await reportsRepo.inventory();
      await reportsRepo.purchases(from: from, to: now);
      await reportsRepo.cash(from: from, to: now);
      await reportsRepo.costing();
    },
    skip: _live ? false : 'set --dart-define=LIVE=1 to run against the linked project',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
