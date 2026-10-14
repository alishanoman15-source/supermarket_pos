import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../providers/pos_providers.dart';

/// Sales history (SPEC §10, screen #47).
class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
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
      if (mounted) {
        ref.read(salesHistoryControllerProvider.notifier).search(value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = ref.watch(salesHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.salesHistory),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) =>
                ref.read(salesHistoryControllerProvider.notifier).setStatus(value),
            itemBuilder: (context) => [
              PopupMenuItem(value: null, child: Text(l10n.statusAll)),
              PopupMenuItem(value: 'completed', child: Text(l10n.statusCompleted)),
              PopupMenuItem(value: 'returned', child: Text(l10n.statusReturned)),
              PopupMenuItem(value: 'cancelled', child: Text(l10n.statusCancelled)),
            ],
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
                hintText: l10n.searchInvoice,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(salesHistoryControllerProvider.notifier).refresh(),
              child: history.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    error is AppException ? error.message : l10n.somethingWentWrong,
                  ),
                ),
                data: (state) {
                  if (state.items.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 120),
                        Text(l10n.noSalesYet, textAlign: TextAlign.center),
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
                                    onPressed: () => ref
                                        .read(salesHistoryControllerProvider.notifier)
                                        .loadMore(),
                                    child: Text(l10n.loadMore),
                                  ),
                          ),
                        );
                      }
                      final sale = state.items[index];
                      return ListTile(
                        title: Text(sale.invoiceNumber),
                        subtitle: Text('${sale.status} · ${_time(sale.soldAt)}'),
                        trailing: Text(
                          formatMoney(sale.grandTotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () => context.push('${AppRoutes.sales}/${sale.id}'),
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

  String _time(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
