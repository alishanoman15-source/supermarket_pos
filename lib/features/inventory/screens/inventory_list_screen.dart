import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../providers/inventory_providers.dart';

/// On-hand stock per branch (SPEC §35, screen #28).
class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key});

  @override
  ConsumerState<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(onHandControllerProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onHand = ref.watch(onHandControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventory),
        actions: [
          IconButton(
            tooltip: l10n.stockCounts,
            icon: const Icon(Icons.checklist),
            onPressed: () => context.push(AppRoutes.stockCounts),
          ),
          IconButton(
            tooltip: l10n.stockTransfers,
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => context.push(AppRoutes.stockTransfers),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          ref.read(onHandControllerProvider.notifier).search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(onHandControllerProvider.notifier).refresh(),
              child: onHand.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _InventoryError(
                  message: error is AppException ? error.message : l10n.somethingWentWrong,
                  onRetry: () => ref.invalidate(onHandControllerProvider),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        const Icon(Icons.inventory_2_outlined, size: 56),
                        const SizedBox(height: 16),
                        Text(l10n.noResults, textAlign: TextAlign.center),
                      ],
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
                                    onPressed: () => ref.read(onHandControllerProvider.notifier).loadMore(),
                                    child: Text(l10n.loadMore),
                                  ),
                          ),
                        );
                      }
                      final record = state.items[index];
                      return ListTile(
                        leading: record.isLow
                            ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                            : const Icon(Icons.inventory_2_outlined),
                        title: Text(record.name),
                        subtitle: Text([
                          if (record.sku != null) '${l10n.sku}: ${record.sku}',
                          '${l10n.reorderLevel}: ${formatQty(record.reorderLevel)}',
                        ].join('  ·  ')),
                        trailing: Text(
                          formatQty(record.onHand),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: record.isLow ? Colors.orange : null,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        onTap: () => context.push('${AppRoutes.stockProduct}/${record.productId}'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InventoryError({required this.message, required this.onRetry});

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
