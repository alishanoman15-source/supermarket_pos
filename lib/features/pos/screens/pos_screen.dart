import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../data/local/held_cart_store.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/product.dart';
import '../../../data/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shifts/providers/shift_providers.dart';
import '../providers/cart_controller.dart';
import '../providers/pos_providers.dart';

/// POS terminal (SPEC §10, §33, §88 — screen #10).
///
/// Catalog/search on the left, cart on the right in landscape; stacked on
/// phones. The focused field doubles as keyboard-wedge scanner capture.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  String _query = '';
  String? _lastScan;
  DateTime? _lastScanAt;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // 40 ms keystroke debounce (SPEC §88).
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 40), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  /// Enter terminates a scan: exact barcode/SKU first, then search fallback.
  Future<void> _onSubmitted(String value) async {
    final code = value.trim();
    if (code.isEmpty) return;

    // Ignore duplicate reads within 300 ms (SPEC §88).
    final now = DateTime.now();
    if (_lastScan == code &&
        _lastScanAt != null &&
        now.difference(_lastScanAt!) < const Duration(milliseconds: 300)) {
      return;
    }
    _lastScan = code;
    _lastScanAt = now;

    final repo = ref.read(productRepositoryProvider);
    setState(() => _query = code);
    try {
      var product = await repo.fetchByBarcode(code);
      product ??= await repo.fetchBySku(code);
      if (!mounted) return;
      if (product == null) {
        _toast(context.l10n.productNotFound);
        return;
      }
      await _addProduct(product);
      if (!mounted) return;
      _searchController.clear();
      setState(() => _query = '');
    } on AppException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _addProduct(Product product) async {
    if (!product.isActive) {
      _toast(context.l10n.productInactive);
      return;
    }
    if (product.isWeightBased) {
      final qty = await _askQty(product);
      if (qty == null || !mounted) return;
      ref.read(cartControllerProvider.notifier).addProduct(product, qty: qty);
    } else {
      ref.read(cartControllerProvider.notifier).addProduct(product);
    }
  }

  Future<Decimal?> _askQty(Product product) async {
    final controller = TextEditingController(text: '1');
    final result = await showDialog<Decimal>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(product.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: dialogContext.l10n.qty,
            helperText: dialogContext.l10n.weightBased,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = Decimal.tryParse(controller.text.trim());
              if (parsed == null || parsed <= Decimal.zero) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _holdCart() async {
    final cart = ref.read(cartControllerProvider);
    if (cart.isEmpty) {
      _toast(context.l10n.cartEmpty);
      return;
    }
    final label = cart.customerName ?? '${cart.lineCount} items';
    await ref.read(heldCartsControllerProvider.notifier).hold(
          HeldCart(
            id: const Uuid().v4(),
            label: label,
            customerName: cart.customerName,
            heldAt: DateTime.now(),
            cart: cart,
          ),
        );
    ref.read(cartControllerProvider.notifier).clear();
    if (!mounted) return;
    _toast(context.l10n.cartHeld);
  }

  /// Cart-level discount (SPEC §16). The value is re-validated server-side in
  /// `complete_sale` against the `pricing.discount_cart` permission.
  Future<void> _editCartDiscount() async {
    final cart = ref.read(cartControllerProvider);
    final controller = TextEditingController(
      text: cart.cartDiscount > Decimal.zero ? cart.cartDiscount.toString() : '',
    );
    final result = await showDialog<Decimal>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.cartDiscount),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: dialogContext.l10n.amount,
            helperText: dialogContext.l10n.permissionRequiredHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              final parsed = text.isEmpty ? Decimal.zero : Decimal.tryParse(text);
              if (parsed == null || parsed < Decimal.zero) return;
              Navigator.pop(dialogContext, parsed);
            },
            child: Text(dialogContext.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    ref.read(cartControllerProvider.notifier).setCartDiscount(result);
  }

  Future<void> _clearCart() async {
    if (ref.read(cartControllerProvider).isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.clearCart),
        content: Text(dialogContext.l10n.confirmClearCart),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      ref.read(cartControllerProvider.notifier).clear();
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.f2) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f4) {
      _checkout();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f8) {
      _holdCart();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f9) {
      context.push(AppRoutes.posCustomers);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _clearCart();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _checkout() async {
    final cart = ref.read(cartControllerProvider);
    if (!cart.isNotEmpty) {
      _toast(context.l10n.cartEmpty);
      return;
    }
    if (cart.grandTotal <= Decimal.zero) {
      _toast(context.l10n.emptyTotal);
      return;
    }
    final shift = await ref.read(myOpenShiftProvider.future);
    if (!mounted) return;
    if (shift == null) {
      _toast(context.l10n.noOpenShiftHint);
      return;
    }
    if (!mounted) return;
    final completed = await context.push<bool>(AppRoutes.posPayment);
    if (completed == true && mounted) {
      ref.read(cartControllerProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final shift = ref.watch(myOpenShiftProvider);
    ref.watch(currentBusinessProvider);

    // Keep client totals consistent with the server's tax-inclusive setting.
    ref.listen(currentBusinessProvider, (_, next) {
      final inclusive = next.valueOrNull?.taxInclusive;
      if (inclusive != null) {
        ref.read(cartControllerProvider.notifier).setTaxInclusive(inclusive);
      }
    });

    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Focus(
      autofocus: false,
      onKeyEvent: _onKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.pos),
          actions: [
            IconButton(
              tooltip: l10n.heldCarts,
              icon: const Icon(Icons.pause_circle_outline),
              onPressed: () => context.push(AppRoutes.posHeld),
            ),
            IconButton(
              tooltip: l10n.salesHistory,
              icon: const Icon(Icons.receipt_long_outlined),
              onPressed: () => context.push(AppRoutes.sales),
            ),
            IconButton(
              tooltip: l10n.cameraScanner,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => context.push(AppRoutes.posCamera),
            ),
          ],
        ),
        body: Column(
          children: [
            if (shift.valueOrNull == null && !shift.isLoading)
              _ShiftBanner(onOpen: () => context.push(AppRoutes.shiftNew)),
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        Expanded(child: _buildCatalog(l10n)),
                        const VerticalDivider(width: 1),
                        SizedBox(width: 380, child: _buildCart(l10n, cart)),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildCatalog(l10n)),
                        const Divider(height: 1),
                        // Tall enough that the totals block and the Hold/Pay
                        // row always fit without the footer overlapping the
                        // list (the old 220dp left the cart lines invisible).
                        SizedBox(
                          height: 300,
                          child: _buildCart(l10n, cart),
                        ),
                      ],
                    ),
            ),
          ],
        ),
        // No floating Pay button on phones: the cart footer already owns a
        // Hold/Pay row, and a FAB floating on top of it made both tappable at
        // once (the tap target overlapped). Desktop keeps a two-column layout
        // where no FAB is needed either.
      ),
    );
  }

  Widget _buildCatalog(AppLocalizations l10n) {
    final products = ref.watch(posProductsProvider(_query));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.scanOrSearch,
              prefixIcon: const Icon(Icons.qr_code),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: products.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorRetry(
              message: error is AppException ? error.message : l10n.somethingWentWrong,
              onRetry: () => ref.invalidate(posProductsProvider(_query)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Center(child: Text(l10n.noResults));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisExtent: 108,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final product = items[index];
                  return _ProductTile(product: product, onTap: () => _addProduct(product));
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCart(AppLocalizations l10n, CartState cart) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: const Icon(Icons.person_outline),
          title: Text(cart.customerName ?? l10n.guestCustomer),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.customer,
            onPressed: () => context.push(AppRoutes.posCustomers),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? Center(child: Text(l10n.cartEmpty))
              : ListView.separated(
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _CartLineTile(line: cart.lines[index]),
                ),
        ),
        const Divider(height: 1),
        _CartTotals(cart: cart, onEditDiscount: _editCartDiscount),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _holdCart,
                  icon: const Icon(Icons.pause),
                  label: Text(l10n.hold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _checkout,
                  icon: const Icon(Icons.payments_outlined),
                  label: Text('${l10n.pay} · ${formatMoney(cart.grandTotal)}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShiftBanner extends StatelessWidget {
  final VoidCallback onOpen;

  const _ShiftBanner({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(l10n.noOpenShiftHint)),
            TextButton(onPressed: onOpen, child: Text(l10n.openShift)),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Row(
                children: [
                  Text(
                    formatMoney(product.sellingPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (product.isWeightBased) const Icon(Icons.scale, size: 14),
                  const SizedBox(width: 4),
                  Text(formatQty(product.stock), style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartLineTile extends ConsumerWidget {
  final CartLine line;

  const _CartLineTile({required this.line});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cartControllerProvider.notifier);
    final l10n = context.l10n;
    return ListTile(
      dense: true,
      title: Text(line.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${formatMoney(line.unitPrice)}'
        '${line.discount > Decimal.zero ? '  -${formatMoney(line.discount)}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => controller.decrement(line.productId),
          ),
          Text(formatQty(line.qty)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => controller.increment(line.productId),
          ),
          SizedBox(
            width: 80,
            child: Text(
              formatMoney(line.net),
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: l10n.lineOptions,
            icon: const Icon(Icons.more_vert),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => _LineOptionsSheet(line: line),
            ),
          ),
        ],
      ),
    );
  }
}

/// Line-level quantity, discount and price override (permission-checked in DB).
class _LineOptionsSheet extends ConsumerStatefulWidget {
  final CartLine line;

  const _LineOptionsSheet({required this.line});

  @override
  ConsumerState<_LineOptionsSheet> createState() => _LineOptionsSheetState();
}

class _LineOptionsSheetState extends ConsumerState<_LineOptionsSheet> {
  late final TextEditingController _qty =
      TextEditingController(text: formatQty(widget.line.qty));
  late final TextEditingController _discount =
      TextEditingController(text: widget.line.discount.toString());
  late final TextEditingController _price =
      TextEditingController(text: widget.line.unitPrice.toString());

  @override
  void dispose() {
    _qty.dispose();
    _discount.dispose();
    _price.dispose();
    super.dispose();
  }

  void _apply() {
    final controller = ref.read(cartControllerProvider.notifier);
    final qty = Decimal.tryParse(_qty.text.trim());
    final discount = Decimal.tryParse(_discount.text.trim());
    final price = Decimal.tryParse(_price.text.trim());
    if (qty != null) controller.setQty(widget.line.productId, qty);
    if (discount != null) controller.setLineDiscount(widget.line.productId, discount);
    if (price != null) controller.setPriceOverride(widget.line.productId, price);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.line.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _qty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.qty),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _discount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.lineDiscount,
              helperText: l10n.permissionRequiredHint,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.priceOverride,
              helperText: l10n.permissionRequiredHint,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: _apply, child: Text(l10n.save)),
        ],
      ),
    );
  }
}

class _CartTotals extends StatelessWidget {
  final CartState cart;
  final VoidCallback onEditDiscount;

  const _CartTotals({required this.cart, required this.onEditDiscount});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget row(String label, Decimal value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text(formatMoney(value))],
          ),
        );
    // Cart discount is editable here; line discounts are shown read-only and
    // are edited per line through the line options sheet.
    Widget cartDiscountRow() => InkWell(
          onTap: onEditDiscount,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text(l10n.cartDiscount),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 14),
                const Spacer(),
                Text(
                  cart.cartDiscount > Decimal.zero
                      ? '-${formatMoney(cart.cartDiscount)}'
                      : formatMoney(Decimal.zero),
                ),
              ],
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          row(l10n.subtotal, cart.subtotal),
          if (cart.lineDiscountTotal > Decimal.zero)
            row(l10n.lineDiscount, cart.lineDiscountTotal),
          cartDiscountRow(),
          if (cart.taxTotal > Decimal.zero) row(l10n.tax, cart.taxTotal),
          const Divider(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  formatMoney(cart.grandTotal),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
