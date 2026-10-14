import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/platform/io_compat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;

import '../../../core/errors/app_exception.dart';
// `Category` also exists as a Flutter annotation, so prefix our models.
import '../../../data/models/category.dart' as models;
import '../../../data/models/product.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/product_repository.dart';
import '../../auth/providers/session_controller.dart';

/// Immutable page state for the product list (search + pagination).
class ProductsState {
  final List<Product> items;
  final bool hasMore;
  final bool loadingMore;
  final String query;

  const ProductsState({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
  });

  ProductsState copyWith({
    List<Product>? items,
    bool? hasMore,
    bool? loadingMore,
    String? query,
  }) => ProductsState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    query: query ?? this.query,
  );
}

class ProductsController extends AutoDisposeAsyncNotifier<ProductsState> {
  static const _page = ProductRepository.pageSize;

  @override
  Future<ProductsState> build() => _fetch('');

  Future<ProductsState> _fetch(String query, {int offset = 0}) async {
    final repo = ref.read(productRepositoryProvider);
    final items = await repo.fetchPage(
      offset: offset,
      limit: _page,
      query: query,
    );
    return ProductsState(
      items: items,
      hasMore: items.length == _page,
      query: query,
    );
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
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next.items],
          hasMore: next.hasMore,
          loadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint('loadMore failed: $e');
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

final productsControllerProvider =
    AutoDisposeAsyncNotifierProvider<ProductsController, ProductsState>(
      ProductsController.new,
    );

/// Full (cost-aware) projection for the product detail screen (SPEC §71).
final productDetailProvider = FutureProvider.autoDispose
    .family<Product?, String>(
      (ref, id) => ref.watch(productRepositoryProvider).fetchFullById(id),
    );

final categoriesProvider = FutureProvider.autoDispose<List<models.Category>>((
  ref,
) async {
  final profile = ref.watch(sessionControllerProvider).profile;
  try {
    final categories = await ref
        .watch(catalogRepositoryProvider)
        .fetchCategories();
    if (profile?.businessId != null) {
      await ref
          .read(offlineSyncRepositoryProvider)
          .cacheCategories(
            profile!.businessId!,
            categories
                .map(
                  (category) => {
                    'id': category.id,
                    'name': category.name,
                    'status': category.status,
                  },
                )
                .toList(),
          );
    }
    return categories;
  } on AppException catch (error) {
    if (error.cause is! IOException &&
        error.cause is! ClientException &&
        error.cause is! TimeoutException) {
      rethrow;
    }
    if (profile?.businessId == null) rethrow;
    final cached = await ref
        .read(offlineSyncRepositoryProvider)
        .cachedCategories(profile!.businessId!);
    if (cached.isEmpty) rethrow;
    return cached;
  }
});

final brandsProvider = FutureProvider.autoDispose<List<models.Brand>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchBrands(),
);

final unitsProvider = FutureProvider.autoDispose<List<models.Unit>>(
  (ref) => ref.watch(catalogRepositoryProvider).fetchUnits(),
);
