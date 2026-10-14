import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product.dart';
import '../../../data/providers.dart';
import '../providers/catalog_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(productsControllerProvider.notifier).search(value);
    });
  }

  Future<void> _archive(Product product) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.archive),
        content: Text('${l10n.confirmDelete}\n${product.name}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.archive)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(productRepositoryProvider).archive(product.id);
      ref.invalidate(productsControllerProvider);
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = ref.watch(productsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.products),
        actions: [
          IconButton(
            tooltip: l10n.categories,
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push(AppRoutes.categories),
          ),
          IconButton(
            tooltip: l10n.brands,
            icon: const Icon(Icons.local_offer_outlined),
            onPressed: () => context.push(AppRoutes.brands),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          ref.read(productsControllerProvider.notifier).search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(productsControllerProvider.notifier).refresh(),
              child: products.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  message: error is AppException ? error.message : l10n.somethingWentWrong,
                  onRetry: () => ref.invalidate(productsControllerProvider),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return _EmptyState(
                      message: _search.text.trim().isEmpty ? l10n.noProducts : l10n.noResults,
                    );
                  }
                  return ListView.separated(
                    itemCount: state.items.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: state.loadingMore
                                ? const CircularProgressIndicator()
                                : OutlinedButton(
                                    onPressed: () => ref.read(productsControllerProvider.notifier).loadMore(),
                                    child: Text(l10n.loadMore),
                                  ),
                          ),
                        );
                      }
                      final product = state.items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(product.name.characters.first.toUpperCase()),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          [
                            if (product.sku?.isNotEmpty == true) '${l10n.sku}: ${product.sku}',
                            if (product.barcode?.isNotEmpty == true) '${l10n.barcode}: ${product.barcode}',
                          ].join('  ·  '),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatMoney(product.sellingPrice)),
                            Text('${l10n.inventory}: ${formatQty(product.stock)}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        onTap: () => context.push('${AppRoutes.products}/${product.id}'),
                        onLongPress: () => _archive(product),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.productNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addProduct),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.inventory_2_outlined, size: 56),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 56),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: Text(context.l10n.retry))),
      ],
    );
  }
}
