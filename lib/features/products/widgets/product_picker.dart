import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product.dart';
import '../../../data/providers.dart';

/// Searchable product picker used by purchase order / goods receive editors.
/// Returns the chosen [Product] or null when dismissed.
Future<Product?> showProductPicker(BuildContext context, WidgetRef ref) {
  return showDialog<Product>(
    context: context,
    builder: (context) => const _ProductPickerDialog(),
  );
}

class _ProductPickerDialog extends ConsumerStatefulWidget {
  const _ProductPickerDialog();

  @override
  ConsumerState<_ProductPickerDialog> createState() => _ProductPickerDialogState();
}

class _ProductPickerDialogState extends ConsumerState<_ProductPickerDialog> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Product> _results = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _run(value));
  }

  Future<void> _run(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(productRepositoryProvider)
          .fetchPage(offset: 0, limit: 40, query: query);
      if (mounted) setState(() => _results = items);
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.products),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchProducts,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _results.isEmpty
                          ? Center(child: Text(l10n.noResults))
                          : ListView.builder(
                              itemCount: _results.length,
                              itemBuilder: (context, i) {
                                final product = _results[i];
                                return ListTile(
                                  title: Text(product.name),
                                  subtitle: Text([
                                    if (product.sku?.isNotEmpty == true) product.sku!,
                                    if (product.barcode?.isNotEmpty == true) product.barcode!,
                                  ].join(' · ')),
                                  trailing: Text(
                                    product.purchasePrice == null
                                        ? formatMoney(product.sellingPrice)
                                        : formatMoney(product.purchasePrice!),
                                  ),
                                  onTap: () => Navigator.pop(context, product),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
