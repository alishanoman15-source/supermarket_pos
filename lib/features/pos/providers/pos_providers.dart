import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/platform/io_compat.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/local/held_cart_store.dart';
import '../../../data/models/business.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/sale.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/pos_repository.dart';
import '../../auth/providers/session_controller.dart';

/// Current business (for currency, tax-inclusive flag, receipt footer).
final currentBusinessProvider = FutureProvider.autoDispose<Business?>((ref) async {
  final businessId = ref.watch(sessionControllerProvider).profile?.businessId;
  if (businessId == null) return null;
  return ref.watch(businessRepositoryProvider).fetchById(businessId);
});

/// POS catalogue search (server fallback until the Drift cache lands in §61).
final posProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>((ref, query) async {
  final profile = ref.watch(sessionControllerProvider).profile;
  final online = ref.watch(productRepositoryProvider);
  try {
    final products = await online.fetchPage(query: query, limit: 50);
    if (profile?.businessId != null && profile?.branchId != null) {
      await ref.read(offlineSyncRepositoryProvider).cacheProducts(
        profile!.businessId!,
        profile.branchId!,
        products.map((product) => {
          'id': product.id,
          'name': product.name,
          'sku': product.sku,
          'barcode': product.barcode,
          'category_id': product.categoryId,
          'brand_id': product.brandId,
          'unit_id': product.unitId,
          'selling_price': product.sellingPrice.toString(),
          'tax_rate': product.taxRate.toString(),
          'is_weight_based': product.isWeightBased,
          'track_batch': product.trackBatch,
          'reorder_level': product.reorderLevel.toString(),
          'stock': product.stock.toString(),
          'status': product.status,
          'image_url': product.imageUrl,
          'description': product.description,
        }),
      );
      await _warmPosCatalog(ref, profile.businessId!, profile.branchId!);
    }
    return products;
  } on AppException catch (error) {
    if (!_isNetworkFailure(error)) rethrow;
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    final cached = await ref.read(offlineSyncRepositoryProvider).searchCachedProducts(
      businessId: profile!.businessId!,
      branchId: profile.branchId!,
      query: query,
    );
    if (cached.isEmpty) rethrow;
    return cached;
  } on PostgrestException catch (error) {
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    final cached = await ref.read(offlineSyncRepositoryProvider).searchCachedProducts(
      businessId: profile!.businessId!,
      branchId: profile.branchId!,
      query: query,
    );
    if (cached.isEmpty) rethrow;
    debugPrint('POS catalogue refresh failed; serving cached products: $error');
    return cached;
  } on IOException catch (error) {
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    final cached = await ref.read(offlineSyncRepositoryProvider).searchCachedProducts(
      businessId: profile!.businessId!,
      branchId: profile.branchId!,
      query: query,
    );
    if (cached.isEmpty) rethrow;
    debugPrint('POS catalogue refresh failed; serving cached products: $error');
    return cached;
  } on ClientException catch (error) {
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    final cached = await ref.read(offlineSyncRepositoryProvider).searchCachedProducts(
      businessId: profile!.businessId!,
      branchId: profile.branchId!,
      query: query,
    );
    if (cached.isEmpty) rethrow;
    debugPrint('POS catalogue refresh failed; serving cached products: $error');
    return cached;
  } on TimeoutException catch (error) {
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    final cached = await ref.read(offlineSyncRepositoryProvider).searchCachedProducts(
      businessId: profile!.businessId!,
      branchId: profile.branchId!,
      query: query,
    );
    if (cached.isEmpty) rethrow;
    debugPrint('POS catalogue refresh failed; serving cached products: $error');
    return cached;
  }
});

/// Exact barcode lookup used by the keyboard-wedge scanner path.
final productByBarcodeProvider =
    FutureProvider.autoDispose.family<Product?, String>((ref, barcode) async {
  final profile = ref.watch(sessionControllerProvider).profile;
  try {
    final product =
        await ref.watch(productRepositoryProvider).fetchByBarcode(barcode);
    if (product != null &&
        profile?.businessId != null &&
        profile?.branchId != null) {
      await ref.read(offlineSyncRepositoryProvider).cacheProducts(
        profile!.businessId!,
        profile.branchId!,
        [{
          'id': product.id,
          'name': product.name,
          'sku': product.sku,
          'barcode': product.barcode,
          'category_id': product.categoryId,
          'brand_id': product.brandId,
          'unit_id': product.unitId,
          'selling_price': product.sellingPrice.toString(),
          'tax_rate': product.taxRate.toString(),
          'is_weight_based': product.isWeightBased,
          'track_batch': product.trackBatch,
          'reorder_level': product.reorderLevel.toString(),
          'stock': product.stock.toString(),
          'status': product.status,
          'image_url': product.imageUrl,
          'description': product.description,
        }],
      );
      await _warmPosCatalog(ref, profile.businessId!, profile.branchId!);
    }
    return product;
  } on AppException catch (error) {
    if (!_isNetworkFailure(error)) rethrow;
    if (profile?.businessId == null || profile?.branchId == null) rethrow;
    return ref.read(offlineSyncRepositoryProvider).cachedProductByBarcode(
          businessId: profile!.businessId!,
          branchId: profile.branchId!,
          barcode: barcode,
        );
  }
});

Future<void> _warmPosCatalog(Ref ref, String businessId, String branchId) async {
  try {
    await ref.read(offlineSyncRepositoryProvider).refreshCatalogIfStale(
          businessId: businessId,
          branchId: branchId,
        );
  } on PostgrestException catch (error) {
    debugPrint('POS catalogue refresh failed: $error');
  } on IOException catch (error) {
    debugPrint('POS catalogue refresh failed: $error');
  } on ClientException catch (error) {
    debugPrint('POS catalogue refresh failed: $error');
  } on TimeoutException catch (error) {
    debugPrint('POS catalogue refresh failed: $error');
  }
}

bool _isNetworkFailure(AppException error) =>
    error.cause is IOException ||
    error.cause is ClientException ||
    error.cause is TimeoutException;

final customerSearchProvider =
    FutureProvider.autoDispose.family<List<Customer>, String>((ref, query) {
  return ref.watch(posRepositoryProvider).searchCustomers(query: query);
});

/// Paginated sales history (RLS scopes visibility by permission, SPEC §75).
class SalesHistoryState {
  final List<Sale> items;
  final bool hasMore;
  final bool loadingMore;
  final String query;
  final String? status;

  const SalesHistoryState({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
    this.status,
  });

  SalesHistoryState copyWith({
    List<Sale>? items,
    bool? hasMore,
    bool? loadingMore,
    String? query,
    String? status,
    bool clearStatus = false,
  }) =>
      SalesHistoryState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        query: query ?? this.query,
        status: clearStatus ? null : (status ?? this.status),
      );
}

class SalesHistoryController extends AutoDisposeAsyncNotifier<SalesHistoryState> {
  static const _page = PosRepository.pageSize;

  @override
  Future<SalesHistoryState> build() => _fetch('', null);

  Future<SalesHistoryState> _fetch(String query, String? status, {int offset = 0}) async {
    final items = await ref.read(posRepositoryProvider).fetchSales(
          offset: offset,
          limit: _page,
          query: query,
          status: status,
        );
    return SalesHistoryState(
      items: items,
      hasMore: items.length == _page,
      query: query,
      status: status,
    );
  }

  Future<void> search(String query) async {
    final status = state.valueOrNull?.status;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query, status));
  }

  Future<void> setStatus(String? status) async {
    final query = state.valueOrNull?.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query, status));
  }

  Future<void> refresh() async {
    final current = state.valueOrNull;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(current?.query ?? '', current?.status));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _fetch(current.query, current.status, offset: current.items.length);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final salesHistoryControllerProvider =
    AutoDisposeAsyncNotifierProvider<SalesHistoryController, SalesHistoryState>(
  SalesHistoryController.new,
);

final saleProvider = FutureProvider.autoDispose.family<Sale?, String>(
  (ref, saleId) => ref.watch(posRepositoryProvider).fetchSale(saleId),
);

final saleItemsProvider = FutureProvider.autoDispose.family<List<SaleItem>, String>(
  (ref, saleId) => ref.watch(posRepositoryProvider).fetchSaleItems(saleId),
);

final salePaymentsProvider =
    FutureProvider.autoDispose.family<List<SalePayment>, String>(
  (ref, saleId) => ref.watch(posRepositoryProvider).fetchSalePayments(saleId),
);

final saleReturnsProvider = FutureProvider.autoDispose.family<List<SaleReturn>, String>(
  (ref, saleId) => ref.watch(posRepositoryProvider).fetchSaleReturns(saleId),
);

/// Held carts for the signed-in cashier on this device (SPEC §62).
class HeldCartsController extends AutoDisposeAsyncNotifier<List<HeldCart>> {
  HeldCartStore get _store => ref.read(heldCartStoreProvider);

  String get _profileId => ref.read(sessionControllerProvider).profile?.id ?? 'anon';

  @override
  Future<List<HeldCart>> build() => _store.load(_profileId);

  Future<void> hold(HeldCart cart) async {
    final carts = [...await _store.load(_profileId), cart];
    await _store.save(_profileId, carts);
    state = AsyncData(carts);
  }

  Future<void> remove(String id) async {
    final carts = (await _store.load(_profileId)).where((c) => c.id != id).toList();
    await _store.save(_profileId, carts);
    state = AsyncData(carts);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _store.load(_profileId));
  }
}

final heldCartsControllerProvider =
    AutoDisposeAsyncNotifierProvider<HeldCartsController, List<HeldCart>>(
  HeldCartsController.new,
);
