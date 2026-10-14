import 'dart:math';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/barcode.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/category.dart';
import '../../../data/providers.dart';
import '../../auth/providers/permissions_controller.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/catalog_providers.dart';

/// Creates (when [productId] is null) or edits a product. Writes go straight to
/// the `products` table; RLS + permission checks guard the row (SPEC §71).
class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _barcode = TextEditingController();
  final _selling = TextEditingController();
  final _purchase = TextEditingController();
  final _tax = TextEditingController(text: '0');
  final _reorder = TextEditingController(text: '0');
  // Free-text taxonomy fields (SPEC §71 UX): typing an existing name reuses
  // its row; a new name creates the category/brand/unit on save. The old
  // dropdowns rendered empty for a fresh business and confused cashiers.
  final _category = TextEditingController();
  final _brand = TextEditingController();
  final _unit = TextEditingController();
  final _categoryFocus = FocusNode();
  final _brandFocus = FocusNode();
  final _unitFocus = FocusNode();

  bool _weightBased = false;
  bool _busy = false;
  bool _loading = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final product = await ref.read(productRepositoryProvider).fetchById(widget.productId!);
      if (product != null && mounted) {
        _name.text = product.name;
        _sku.text = product.sku ?? '';
        _barcode.text = product.barcode ?? '';
        _selling.text = product.sellingPrice.toString();
        _tax.text = product.taxRate.toString();
        _reorder.text = product.reorderLevel.toString();
        _weightBased = product.isWeightBased;
        // Best-effort name prefill for the free-text fields; a failed
        // lookup just leaves the field blank and never blocks editing.
        _category.text = await _nameOf(categoriesProvider, product.categoryId);
        _brand.text = await _nameOf(brandsProvider, product.brandId);
        _unit.text = await _nameOf(unitsProvider, product.unitId);
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _nameOf<T>(
    AutoDisposeFutureProvider<List<T>> provider,
    String? id,
  ) async {
    if (id == null) return '';
    try {
      final items = await ref.read(provider.future);
      for (final item in items) {
        if (item is Category && item.id == id) return item.name;
        if (item is Brand && item.id == id) return item.name;
        if (item is Unit && item.id == id) return item.name;
      }
    } catch (_) {
      // Lookup lists are cosmetic here; saving re-resolves everything.
    }
    return '';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _sku,
      _barcode,
      _selling,
      _purchase,
      _tax,
      _reorder,
      _category,
      _brand,
      _unit,
    ]) {
      c.dispose();
    }
    _categoryFocus.dispose();
    _brandFocus.dispose();
    _unitFocus.dispose();
    super.dispose();
  }

  void _generateBarcode() {
    // Business-reserved internal range: '200' + 9 digits → EAN-13 (SPEC §104).
    final random = Random();
    final body = '200${List.generate(9, (_) => random.nextInt(10)).join()}';
    _barcode.text = buildEan13(body);
    setState(() {});
  }

  /// Best-effort lookup list for name→id resolution; an unreadable list
  /// just means "nothing matched yet" and the caller creates the row.
  Future<List<T>> _listOrEmpty<T>(
    AutoDisposeFutureProvider<List<T>> provider,
  ) async {
    try {
      return await ref.read(provider.future);
    } catch (_) {
      return <T>[];
    }
  }

  /// Case-insensitive exact-name match against the loaded taxonomy rows.
  String? _findIdByName(List<dynamic> items, String typed) {
    final lower = typed.toLowerCase();
    for (final item in items) {
      switch (item) {
        case Category(:final id, :final name) when name.toLowerCase() == lower:
          return id;
        case Brand(:final id, :final name) when name.toLowerCase() == lower:
          return id;
        case Unit(:final id, :final name) when name.toLowerCase() == lower:
          return id;
      }
    }
    return null;
  }

  String? _decimalValidator(String? value, String field) {
    final l10n = context.l10n;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.required;
    final parsed = Decimal.tryParse(v);
    if (parsed == null || parsed < Decimal.zero) return l10n.invalidNumber;
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (businessId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorNoBusiness)));
      return;
    }

    // Resolve the typed category/brand/unit names: an existing row with the
    // same name is reused, a new name creates the row (RLS still requires
    // products.create — the same permission this form already needs). Empty
    // text simply leaves the optional relation null.
    String? categoryId;
    String? brandId;
    String? unitId;
    try {
      final typedCategory = _category.text.trim();
      if (typedCategory.isNotEmpty) {
        categoryId = _findIdByName(await _listOrEmpty(categoriesProvider), typedCategory) ??
            await ref.read(catalogRepositoryProvider).createCategory(
                  businessId: businessId,
                  name: typedCategory,
                );
      }
      final typedBrand = _brand.text.trim();
      if (typedBrand.isNotEmpty) {
        brandId = _findIdByName(await _listOrEmpty(brandsProvider), typedBrand) ??
            await ref.read(catalogRepositoryProvider).createBrand(
                  businessId: businessId,
                  name: typedBrand,
                );
      }
      final typedUnit = _unit.text.trim();
      if (typedUnit.isNotEmpty) {
        unitId = _findIdByName(await _listOrEmpty(unitsProvider), typedUnit) ??
            await ref.read(catalogRepositoryProvider).createUnit(
                  businessId: businessId,
                  name: typedUnit,
                );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }

    final values = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
      'barcode': _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      'selling_price': _selling.text.trim(),
      'tax_rate': _tax.text.trim().isEmpty ? '0' : _tax.text.trim(),
      'reorder_level': _reorder.text.trim().isEmpty ? '0' : _reorder.text.trim(),
      'is_weight_based': _weightBased,
      'category_id': categoryId,
      'brand_id': brandId,
      'unit_id': unitId,
      'status': 'active',
    };
    // Cost price is permission-gated (`products.view_cost`). A role without
    // it never sees the field, so the key is omitted entirely — on edit the
    // stored cost is preserved (never clobbered with 0), and on create the
    // column default (0) applies. The server strips the column anyway for
    // such roles (SPEC §71); this only keeps the UI honest.
    if (ref.read(accessPolicyProvider).grants('products.view_cost')) {
      values['purchase_price'] =
          _purchase.text.trim().isEmpty ? '0' : _purchase.text.trim();
    }

    setState(() => _busy = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.productId!, values);
      } else {
        await repo.create(businessId: businessId, values: values);
      }
      ref.invalidate(productsControllerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Existing names feed the inline autocomplete; an empty list (fresh
    // business) simply means free typing with create-on-save.
    final categoryOptions =
        ref.watch(categoriesProvider).valueOrNull?.map((c) => c.name).toList() ??
            const <String>[];
    final brandOptions =
        ref.watch(brandsProvider).valueOrNull?.map((b) => b.name).toList() ??
            const <String>[];
    final unitOptions =
        ref.watch(unitsProvider).valueOrNull?.map((u) => u.name).toList() ??
            const <String>[];
    // Cost price only for holders of `products.view_cost` (SPEC §71) — a
    // cashier or custom role without it never sees the purchase price.
    final canViewCost =
        ref.watch(accessPolicyProvider).grants('products.view_cost');

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editProduct : l10n.addProduct)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _name,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.productName),
                        validator: (v) => Validators.requiredText(v, message: l10n.required),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sku,
                        decoration: InputDecoration(labelText: l10n.sku),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _barcode,
                        decoration: InputDecoration(
                          labelText: l10n.barcode,
                          suffixIcon: IconButton(
                            tooltip: l10n.generateBarcode,
                            icon: const Icon(Icons.qr_code_2),
                            onPressed: _generateBarcode,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _selling,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: l10n.sellingPrice),
                              validator: (v) => _decimalValidator(v, l10n.sellingPrice),
                            ),
                          ),
                          if (canViewCost) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _purchase,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration:
                                    InputDecoration(labelText: l10n.purchasePrice),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tax,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: l10n.taxRate),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _reorder,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: l10n.reorderLevel),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TaxonomyField(
                        label: l10n.category,
                        icon: Icons.category_outlined,
                        controller: _category,
                        focusNode: _categoryFocus,
                        options: categoryOptions,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _TaxonomyField(
                        label: l10n.brand,
                        icon: Icons.branding_watermark_outlined,
                        controller: _brand,
                        focusNode: _brandFocus,
                        options: brandOptions,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _TaxonomyField(
                        label: l10n.unit,
                        icon: Icons.straighten_outlined,
                        controller: _unit,
                        focusNode: _unitFocus,
                        options: unitOptions,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: _weightBased,
                        onChanged: (v) => setState(() => _weightBased = v),
                        title: Text(l10n.weightBased),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: _busy
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(l10n.save),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// A taxonomy name field (category / brand / unit) with inline suggestions:
/// typing filters the business's existing rows, tapping one fills the field.
/// Anything else stays free text and is created on save — so the field never
/// blocks a fresh business (whose lists are empty) and never forces a
/// dropdown hunt (SPEC §71 UX).
class _TaxonomyField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<String> options;
  final TextInputAction? textInputAction;

  const _TaxonomyField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.focusNode,
    required this.options,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (option) => option,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const <String>[];
        // Prefix matches first, then substring matches, alphabetical inside
        // each group — typing "sn" puts "Snacks" above "Peanut Snacks".
        final prefix = <String>[];
        final substring = <String>[];
        for (final name in options) {
          final lower = name.toLowerCase();
          if (lower.startsWith(query)) {
            prefix.add(name);
          } else if (lower.contains(query)) {
            substring.add(name);
          }
        }
        prefix.sort();
        substring.sort();
        return [...prefix, ...substring];
      },
      fieldViewBuilder:
          (context, fieldController, fieldFocusNode, onFieldSubmitted) =>
              TextFormField(
        controller: fieldController,
        focusNode: fieldFocusNode,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: textInputAction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
      // Anchored to the field by RawAutocomplete's own composited follower.
      optionsViewBuilder: (context, onSelected, iterableOptions) {
        final displayedOptions = iterableOptions.toList();
        return Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: displayedOptions.length,
              itemBuilder: (context, index) {
                final option = displayedOptions[index];
                return InkWell(
                  onTap: () => onSelected(option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _highlighted(
                            context,
                            option,
                            controller.text.trim().toLowerCase(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),            ),
          ),
        );
      },
    );
  }

  /// Renders [text] with the matched part ([query], lower-case index) bolded
  /// in the primary colour so the reason a row matched is obvious.
  Widget _highlighted(BuildContext context, String text, String query) {
    final scheme = Theme.of(context).colorScheme;
    final start = query.isEmpty ? -1 : text.toLowerCase().indexOf(query);
    if (start < 0) return Text(text);
    final end = start + query.length;
    return Text.rich(
      TextSpan(
        text: text.substring(0, start),
        children: [
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
