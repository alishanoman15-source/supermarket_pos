import 'package:decimal/decimal.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/sale.dart';
import '../../../data/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/providers/session_controller.dart';
import '../../shifts/providers/shift_providers.dart';
import '../providers/cart_controller.dart';
import '../providers/pos_providers.dart';
import '../receipt.dart';

/// Payment + change screen (SPEC §10 step 5, §88 — screen #15). Supports split
/// tenders; totals/change are recomputed by `complete_sale` server-side.
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  static const _methods = ['cash', 'card', 'mobile_wallet', 'other'];

  String _method = 'cash';
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final List<PaymentLine> _payments = [];
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Decimal get _paid => _payments.fold(Decimal.zero, (sum, p) => sum + p.amount);

  Decimal _remaining(Decimal total) {
    final left = total - _paid;
    return left < Decimal.zero ? Decimal.zero : left;
  }

  void _addPayment(Decimal total, {Decimal? amount}) {
    final value = amount ?? Decimal.tryParse(_amount.text.trim());
    if (value == null || value <= Decimal.zero) return;
    setState(() {
      _payments.add(
        PaymentLine(
          method: _method,
          amount: value,
          reference: _reference.text.trim().isEmpty
              ? null
              : _reference.text.trim(),
        ),
      );
      _amount.clear();
      _reference.clear();
    });
  }

  Future<void> _complete(Decimal total) async {
    if (_payments.isEmpty) return;
    final cart = ref.read(cartControllerProvider);
    final shift = await ref.read(myOpenShiftProvider.future);
    if (!mounted) return;
    if (shift == null) {
      _snack(context.l10n.noOpenShiftHint);
      return;
    }

    setState(() => _busy = true);
    try {
      final profile = ref.read(sessionControllerProvider).profile;
      if (profile?.businessId == null) {
        throw StateError('The signed-in cashier has no business profile.');
      }
      final idempotencyKey = const Uuid().v4();
      final connectivity = await Connectivity().checkConnectivity();
      final offlineMode = connectivity.every(
        (result) => result == ConnectivityResult.none,
      );
      final submission = await ref
          .read(offlineSyncRepositoryProvider)
          .enqueueSale(
            businessId: profile!.businessId!,
            branchId: shift.branchId,
            shiftId: shift.id,
            cashierId: profile.id,
            idempotencyKey: idempotencyKey,
            offlineMode: offlineMode,
            cartDiscount: cart.cartDiscount.toString(),
            items: offlineMode
                ? cart.lines
                      .map(
                        (line) => {
                          ...line.toPayload(),
                          'unit_price': line.unitPrice.toString(),
                        },
                      )
                      .toList()
                : cart.itemsPayload,
            payments: _payments.map((p) => p.toPayload()).toList(),
            itemSnapshots: cart.lines
                .map(
                  (line) => {
                    'product_id': line.productId,
                    'name_snapshot': line.name,
                    'sku_snapshot': line.sku,
                    'barcode_snapshot': line.barcode,
                    'qty': line.qty.toString(),
                    'unit_price': line.unitPrice.toString(),
                    'discount': line.discount.toString(),
                    'tax_rate': line.taxRate.toString(),
                  },
                )
                .toList(),
            subtotal: cart.subtotal.toString(),
            discountTotal: cart.discountTotal.toString(),
            taxTotal: cart.taxTotal.toString(),
            grandTotal: cart.grandTotal.toString(),
            amountPaid: _paid.toString(),
            changeDue: (_paid - cart.grandTotal).toString(),
            customerId: cart.customerId,
            note: cart.note,
          );

      final SaleResult result;
      if (submission.isSynced) {
        final sale = await ref
            .read(posRepositoryProvider)
            .fetchSale(submission.serverSaleId!);
        if (sale == null) {
          throw StateError(
            'The synced sale could not be read back from Supabase.',
          );
        }
        result = SaleResult(
          saleId: sale.id,
          invoiceNumber: sale.invoiceNumber,
          subtotal: sale.subtotal,
          discountTotal: sale.discountTotal,
          taxTotal: sale.taxTotal,
          grandTotal: sale.grandTotal,
          amountPaid: sale.amountPaid,
          changeDue: sale.changeDue,
        );
        ref.invalidate(salesHistoryControllerProvider);
      } else {
        result = SaleResult(
          saleId: submission.localOrderId,
          invoiceNumber:
              'LOCAL-${submission.localOrderId.substring(0, 8).toUpperCase()}',
          subtotal: cart.subtotal,
          discountTotal: cart.discountTotal,
          taxTotal: cart.taxTotal,
          grandTotal: cart.grandTotal,
          amountPaid: _paid,
          changeDue: _paid < cart.grandTotal
              ? Decimal.zero
              : _paid - cart.grandTotal,
          pendingSync: true,
          syncConflict: submission.needsReview,
        );
      }
      if (!mounted) return;
      await _showReceipt(result, cart);
      if (!mounted) return;
      context.pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showReceipt(SaleResult result, CartState cart) async {
    final business = ref.read(currentBusinessProvider).valueOrNull;
    final profile = ref.read(sessionControllerProvider).profile;
    final data = ReceiptData(
      businessName: business?.name ?? '',
      footer: business?.receiptFooter,
      invoiceNumber: result.invoiceNumber,
      soldAt: DateTime.now(),
      cashierName: profile?.name,
      customerName: cart.customerName,
      lines: cart.lines,
      subtotal: result.subtotal,
      discountTotal: result.discountTotal,
      taxTotal: result.taxTotal,
      grandTotal: result.grandTotal,
      payments: _payments,
      changeDue: result.changeDue,
    );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          result.pendingSync
              ? (result.syncConflict
                    ? dialogContext.l10n.saleSyncNeedsReview
                    : dialogContext.l10n.salePendingSync)
              : dialogContext.l10n.saleCompleted,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${result.pendingSync ? dialogContext.l10n.offlineLocalReference : dialogContext.l10n.invoice}: ${result.invoiceNumber}',
              ),
              const SizedBox(height: 8),
              Text(
                '${dialogContext.l10n.total}: ${formatMoney(result.grandTotal)}',
              ),
              Text(
                '${dialogContext.l10n.changeDue}: ${formatMoney(result.changeDue)}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async => shareReceipt(data),
            child: Text(dialogContext.l10n.share),
          ),
          TextButton(
            onPressed: () async => printReceipt(data),
            child: Text(dialogContext.l10n.printReceipt),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = ref.watch(cartControllerProvider);
    final total = cart.grandTotal;
    final remaining = _remaining(total);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.payment)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n.total}: ${formatMoney(total)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('${l10n.remaining}: ${formatMoney(remaining)}'),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  for (final m in _methods)
                    ButtonSegment(value: m, label: Text(_methodLabel(l10n, m))),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(labelText: l10n.amount),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: remaining > Decimal.zero
                        ? () => _addPayment(total, amount: remaining)
                        : null,
                    child: Text(l10n.exact),
                  ),
                ],
              ),
              if (_method != 'cash')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextField(
                    controller: _reference,
                    decoration: InputDecoration(labelText: l10n.reference),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _addPayment(total),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addPayment),
                  ),
                  const Spacer(),
                  Text('${l10n.paid}: ${formatMoney(_paid)}'),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: _payments.isEmpty
                    ? Center(child: Text(l10n.noPaymentsYet))
                    : ListView.builder(
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final p = _payments[index];
                          return ListTile(
                            dense: true,
                            title: Text(_methodLabel(l10n, p.method)),
                            subtitle: p.reference == null
                                ? null
                                : Text(p.reference!),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatMoney(p.amount)),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: _busy
                                      ? null
                                      : () => setState(
                                          () => _payments.removeAt(index),
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              FilledButton(
                onPressed:
                    (_busy || _payments.isEmpty || remaining > Decimal.zero)
                    ? null
                    : () => _complete(total),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.completeSale),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _methodLabel(AppLocalizations l10n, String method) => switch (method) {
    'cash' => l10n.payCash,
    'card' => l10n.payCard,
    'mobile_wallet' => l10n.payWallet,
    _ => l10n.payOther,
  };
}
