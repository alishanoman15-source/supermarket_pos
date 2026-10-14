import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../l10n/l10n.dart';
import 'async_view.dart';

/// Immutable page state shared by every paginated list (SPEC §87).
class PagedState<T> {
  final List<T> items;
  final bool hasMore;
  final bool loadingMore;
  final String query;
  final Map<String, String> filters;

  const PagedState({
    this.items = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.query = '',
    this.filters = const {},
  });

  PagedState<T> copyWith({
    List<T>? items,
    bool? hasMore,
    bool? loadingMore,
    String? query,
    Map<String, String>? filters,
  }) =>
      PagedState<T>(
        items: items ?? this.items,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        query: query ?? this.query,
        filters: filters ?? this.filters,
      );
}

/// Base class for list controllers: search + filters + pagination + refresh.
///
/// Subclasses implement [fetch] (one page, newest-first ordering decided by the
/// repository) and may override [initialFilters] / [pageSize].
abstract class PagedController<T> extends AutoDisposeAsyncNotifier<PagedState<T>> {
  int get pageSize => 50;

  Map<String, String> get initialFilters => const {};

  Future<List<T>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  });

  @override
  Future<PagedState<T>> build() => _load('', initialFilters);

  Future<PagedState<T>> _load(String query, Map<String, String> filters, {int offset = 0}) async {
    final items = await fetch(
      offset: offset,
      limit: pageSize,
      query: query,
      filters: filters,
    );
    return PagedState<T>(
      items: items,
      hasMore: items.length == pageSize,
      query: query,
      filters: filters,
    );
  }

  /// Re-runs the query while keeping the current rows visible, so search feels
  /// instant instead of flashing a skeleton.
  Future<void> _reload(String query, Map<String, String> filters) async {
    if (state.valueOrNull == null) state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(query, filters));
  }

  Future<void> search(String query) =>
      _reload(query, state.valueOrNull?.filters ?? initialFilters);

  Future<void> refresh() =>
      _reload(state.valueOrNull?.query ?? '', state.valueOrNull?.filters ?? initialFilters);

  /// Applies (or clears, when [value] is null/empty) a filter and reloads.
  Future<void> setFilter(String key, String? value) {
    final next = Map<String, String>.from(state.valueOrNull?.filters ?? initialFilters);
    if (value == null || value.isEmpty) {
      next.remove(key);
    } else {
      next[key] = value;
    }
    return _reload(state.valueOrNull?.query ?? '', next);
  }

  /// Convenience for a single-choice filter group.
  Future<void> setExclusiveFilter(String key, String? value) => setFilter(key, value);

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _load(
        current.query,
        current.filters,
        offset: current.items.length,
      );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...next.items],
        hasMore: next.hasMore,
        loadingMore: false,
      ));
    } catch (e) {
      debugPrint('loadMore failed: $e');
      state = AsyncData(current.copyWith(loadingMore: false));
    }
  }
}

/// List screen body: debounced search, optional filter bar, pull-to-refresh,
/// infinite scroll, and the loading/empty/error states (SPEC §87).
class PagedListView<T> extends ConsumerStatefulWidget {
  final AutoDisposeAsyncNotifierProvider<PagedController<T>, PagedState<T>> provider;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String? searchHint;
  final String emptyMessage;
  final IconData emptyIcon;
  final String? emptyActionLabel;
  final VoidCallback? onEmptyAction;
  final Widget Function(BuildContext context, WidgetRef ref, PagedState<T> state)? filterBar;
  final EdgeInsets padding;
  final bool showDividers;

  const PagedListView({
    super.key,
    required this.provider,
    required this.itemBuilder,
    required this.emptyMessage,
    this.searchHint,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.filterBar,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.showDividers = true,
  });

  @override
  ConsumerState<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends ConsumerState<PagedListView<T>> {
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
      ref.read(widget.provider.notifier).search(value);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(widget.provider);
    final state = async.valueOrNull;

    return Column(
      children: [
        if (widget.searchHint != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          ref.read(widget.provider.notifier).search('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
        if (widget.filterBar != null && state != null)
          widget.filterBar!(context, ref, state),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(widget.provider.notifier).refresh(),
            child: async.when(
              loading: () => const LoadingSkeleton(),
              error: (error, _) => ErrorState(
                message: error is AppException
                    ? error.message
                    : l10n.somethingWentWrong,
                onRetry: () => ref.invalidate(widget.provider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return EmptyState(
                    message: widget.emptyMessage,
                    icon: widget.emptyIcon,
                    actionLabel: widget.emptyActionLabel,
                    onAction: widget.onEmptyAction,
                  );
                }
                final extra = page.hasMore ? 1 : 0;
                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: widget.padding,
                  itemCount: page.items.length + extra,
                  separatorBuilder: (_, _) =>
                      widget.showDividers ? const Divider(height: 1) : const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index >= page.items.length) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: page.loadingMore
                              ? const CircularProgressIndicator()
                              : OutlinedButton.icon(
                                  onPressed: () => ref
                                      .read(widget.provider.notifier)
                                      .loadMore(),
                                  icon: const Icon(Icons.expand_more),
                                  label: Text(l10n.loadMore),
                                ),
                        ),
                      );
                    }
                    return widget.itemBuilder(context, page.items[index]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
