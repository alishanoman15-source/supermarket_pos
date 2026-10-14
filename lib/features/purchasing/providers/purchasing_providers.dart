import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/purchase.dart';
import '../../../data/providers.dart';

class PurchaseOrdersController extends PagedController<PurchaseOrder> {
  @override
  Map<String, String> get initialFilters => const {'status': ''};

  @override
  Future<List<PurchaseOrder>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(purchasingRepositoryProvider).fetchPurchaseOrders(
            offset: offset,
            limit: limit,
            query: query,
            status: filters['status'],
          );
}

final purchaseOrdersControllerProvider =
    AutoDisposeAsyncNotifierProvider<PurchaseOrdersController, PagedState<PurchaseOrder>>(
  PurchaseOrdersController.new,
);

final purchaseOrderProvider = FutureProvider.autoDispose.family<PurchaseOrder?, String>(
  (ref, id) => ref.watch(purchasingRepositoryProvider).fetchPurchaseOrder(id),
);

final purchaseOrderItemsProvider =
    FutureProvider.autoDispose.family<List<PurchaseOrderItem>, String>(
  (ref, id) => ref.watch(purchasingRepositoryProvider).fetchPurchaseOrderItems(id),
);

class PurchasesController extends PagedController<Purchase> {
  @override
  Map<String, String> get initialFilters => const {'status': ''};

  @override
  Future<List<Purchase>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(purchasingRepositoryProvider).fetchPurchases(
            offset: offset,
            limit: limit,
            query: query,
            status: filters['status'],
          );
}

final purchasesControllerProvider =
    AutoDisposeAsyncNotifierProvider<PurchasesController, PagedState<Purchase>>(
  PurchasesController.new,
);

final purchaseItemsProvider =
    FutureProvider.autoDispose.family<List<PurchaseItem>, String>(
  (ref, id) => ref.watch(purchasingRepositoryProvider).fetchPurchaseItems(id),
);
