import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/loyalty.dart';
import '../../../data/models/supplier.dart';
import '../../../data/providers.dart';

// --- Suppliers --------------------------------------------------------------
class SuppliersController extends PagedController<Supplier> {
  @override
  Future<List<Supplier>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(partiesRepositoryProvider).fetchSuppliers(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final suppliersControllerProvider =
    AutoDisposeAsyncNotifierProvider<SuppliersController, PagedState<Supplier>>(
  SuppliersController.new,
);

/// Flat, unpaginated supplier list used by pickers (PO form, payments).
final supplierOptionsProvider = FutureProvider.autoDispose<List<Supplier>>(
  (ref) => ref.watch(partiesRepositoryProvider).fetchSuppliers(limit: 200),
);

final supplierProvider = FutureProvider.autoDispose.family<Supplier?, String>(
  (ref, id) => ref.watch(partiesRepositoryProvider).fetchSupplier(id),
);

final supplierPaymentsProvider =
    FutureProvider.autoDispose.family<List<SupplierPayment>, String>(
  (ref, id) => ref.watch(partiesRepositoryProvider).fetchSupplierPayments(id),
);

// --- Customers --------------------------------------------------------------
class CustomersController extends PagedController<Customer> {
  @override
  Future<List<Customer>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(partiesRepositoryProvider).fetchCustomers(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final customersControllerProvider =
    AutoDisposeAsyncNotifierProvider<CustomersController, PagedState<Customer>>(
  CustomersController.new,
);

final customerProvider = FutureProvider.autoDispose.family<Customer?, String>(
  (ref, id) => ref.watch(partiesRepositoryProvider).fetchCustomer(id),
);

final loyaltyTransactionsProvider =
    FutureProvider.autoDispose.family<List<LoyaltyTransaction>, String>(
  (ref, customerId) =>
      ref.watch(partiesRepositoryProvider).fetchLoyaltyTransactions(customerId),
);
