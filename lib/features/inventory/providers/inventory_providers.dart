import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/inventory.dart';
import '../../../data/models/product_batch.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/inventory_repository.dart';

/// Paginated/searchable on-hand list state.
class OnHandState {
  final List<StockRecord> items;
  final bool hasMore;
  final bool loadingMore;
  final String query;

  const OnHandState({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
  });

  OnHandState copyWith({
    List<StockRecord>? items,
    bool? hasMore,
    bool? loadingMore,
    String? query,
  }) =>
      OnHandState(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        query: query ?? this.query,
      );
}

class OnHandController extends AutoDisposeAsyncNotifier<OnHandState> {
  static const _page = InventoryRepository.pageSize;

  @override
  Future<OnHandState> build() => _fetch('');

  Future<OnHandState> _fetch(String query, {int offset = 0}) async {
    final items = await ref
        .read(inventoryRepositoryProvider)
        .fetchOnHand(offset: offset, limit: _page, query: query);
    return OnHandState(items: items, hasMore: items.length == _page, query: query);
  }

  Future<void> search(String query) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query));
  }

  Future<void> refresh() async {
    final query = state.valueOrNull?.query ?? '';
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(query));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _fetch(current.query, offset: current.items.length);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      debugPrint('inventory loadMore failed: $e');
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final onHandControllerProvider =
    AutoDisposeAsyncNotifierProvider<OnHandController, OnHandState>(OnHandController.new);

final stockRecordProvider = FutureProvider.autoDispose.family<StockRecord?, String>(
  (ref, productId) => ref.watch(inventoryRepositoryProvider).fetchOnHandForProduct(productId),
);

/// Broader on-hand snapshot used to resolve product names in count/transfer
/// editors (count items and transfer items only carry ids).
final onHandCatalogProvider = FutureProvider.autoDispose<List<StockRecord>>(
  (ref) => ref.watch(inventoryRepositoryProvider).fetchOnHand(limit: 500),
);

final stockMovementsProvider = FutureProvider.autoDispose
    .family<List<StockMovement>, String>((ref, productId) => ref
        .watch(inventoryRepositoryProvider)
        .fetchMovements(productId));

final stockCountsProvider = FutureProvider.autoDispose<List<StockCount>>(
  (ref) => ref.watch(inventoryRepositoryProvider).fetchCounts(),
);

final stockCountItemsProvider = FutureProvider.autoDispose
    .family<List<StockCountItem>, String>((ref, stockCountId) => ref
        .watch(inventoryRepositoryProvider)
        .fetchCountItems(stockCountId));

final stockTransfersProvider = FutureProvider.autoDispose<List<StockTransfer>>(
  (ref) => ref.watch(inventoryRepositoryProvider).fetchTransfers(),
);

/// Tracked batches / expiry (SPEC §35).
class BatchesController extends PagedController<ProductBatch> {
  @override
  Future<List<ProductBatch>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(inventoryRepositoryProvider).fetchBatches(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final batchesControllerProvider =
    AutoDisposeAsyncNotifierProvider<BatchesController, PagedState<ProductBatch>>(
  BatchesController.new,
);
