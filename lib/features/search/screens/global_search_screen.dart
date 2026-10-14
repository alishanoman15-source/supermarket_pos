import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/product.dart';
import '../../../data/models/supplier.dart';
import '../../../data/providers.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Global search (SPEC §7): products, customers and suppliers from one box,
/// plus quick actions to the most used screens.
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  String? _error;

  List<Product> _products = const [];
  List<Customer> _customers = const [];
  List<Supplier> _suppliers = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _products = const [];
        _customers = const [];
        _suppliers = const [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _run(value.trim()));
  }

  Future<void> _run(String term) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ref
          .read(productRepositoryProvider)
          .fetchPage(offset: 0, limit: 20, query: term);
      final customers = await ref
          .read(partiesRepositoryProvider)
          .fetchCustomers(limit: 10, query: term);
      final suppliers = await ref
          .read(partiesRepositoryProvider)
          .fetchSuppliers(limit: 10, query: term);
      if (mounted) {
        setState(() {
          _products = products;
          _customers = customers;
          _suppliers = suppliers;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasQuery = _search.text.trim().isNotEmpty;
    final noResults =
        hasQuery && !_loading && _products.isEmpty && _customers.isEmpty && _suppliers.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.globalSearch)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchEverything,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView(
                        children: [
                          if (!hasQuery) _quickActions(context, l10n),
                          if (noResults) Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(child: Text(l10n.noSearchResults)),
                          ),
                          if (_products.isNotEmpty) ...[
                            _header(context, l10n.products),
                            for (final p in _products)
                              ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(p.name),
                                subtitle: Text(p.sku ?? p.barcode ?? ''),
                                trailing: Text(money(p.sellingPrice)),
                                onTap: () => context.push('${AppRoutes.productView}/${p.id}'),
                              ),
                          ],
                          if (_customers.isNotEmpty) ...[
                            _header(context, l10n.customers),
                            for (final c in _customers)
                              ListTile(
                                leading: const Icon(Icons.person_outline),
                                title: Text(c.name),
                                subtitle: Text(c.phone ?? ''),
                                onTap: () => context.push('${AppRoutes.customers}/${c.id}'),
                              ),
                          ],
                          if (_suppliers.isNotEmpty) ...[
                            _header(context, l10n.suppliers),
                            for (final s in _suppliers)
                              ListTile(
                                leading: const Icon(Icons.local_shipping_outlined),
                                title: Text(s.name),
                                subtitle: Text(s.phone ?? ''),
                                onTap: () => context.push('${AppRoutes.suppliers}/${s.id}'),
                              ),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _quickActions(BuildContext context, AppLocalizations l10n) {
    final actions = <(IconData, String, String)>[
      (Icons.point_of_sale_outlined, l10n.pos, AppRoutes.pos),
      (Icons.receipt_long_outlined, l10n.purchaseOrders, AppRoutes.purchaseOrders),
      (Icons.bar_chart_outlined, l10n.reportsHub, AppRoutes.reports),
      (Icons.people_outline, l10n.customers, AppRoutes.customers),
      (Icons.local_shipping_outlined, l10n.suppliers, AppRoutes.suppliers),
      (Icons.notifications_outlined, l10n.notifications, AppRoutes.notifications),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(context, l10n.quickActions),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final action in actions)
                ActionChip(
                  avatar: Icon(action.$1, size: 18),
                  label: Text(action.$2),
                  onPressed: () => context.push(action.$3),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
