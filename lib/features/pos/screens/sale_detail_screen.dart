import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/money.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/pos_providers.dart';
import '../receipt.dart';

enum _ReceiptFormat { printPdf, sharePdf, shareEscPos }

/// Sale detail (SPEC §11, screen #48): snapshot lines, tenders, returns and the
/// cancel-sale workflow (reason required, audited server-side).
class SaleDetailScreen extends ConsumerStatefulWidget {
  final String saleId;

  const SaleDetailScreen({super.key, required this.saleId});

  @override
  ConsumerState<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends ConsumerState<SaleDetailScreen> {
  bool _busy = false;

  Future<void> _cancel() async {
    final l10n = context.l10n;
    final reason = await _askReason(l10n.cancelSale, l10n.reasonRequired);
    if (reason == null || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(posRepositoryProvider)
          .cancelSale(saleId: widget.saleId, reason: reason);
      ref.invalidate(saleProvider(widget.saleId));
      ref.invalidate(salesHistoryControllerProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.saleCancelled)));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askReason(String title, String hint) async {    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: dialogContext.l10n.reason),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            child: Text(dialogContext.l10n.ok),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  /// Reprints or shares the stored invoice (SPEC §39, §40) — the lines come
  /// from the sale snapshot, never from today's catalogue price (§95).
  Future<void> _receipt(_ReceiptFormat format) async {
    final l10n = context.l10n;
    final sale = ref.read(saleProvider(widget.saleId)).valueOrNull;
    final items = ref.read(saleItemsProvider(widget.saleId)).valueOrNull;
    final payments = ref.read(salePaymentsProvider(widget.saleId)).valueOrNull;
    if (sale == null || items == null) return;
    final business = ref.read(currentBusinessProvider).valueOrNull;
    final profile = ref.read(sessionControllerProvider).profile;
    final data = ReceiptData.fromSale(
      sale: sale,
      items: items,
      payments: payments ?? const [],
      businessName: business?.name ?? '',
      footer: business?.receiptFooter,
      cashierName: profile?.name,
    );
    try {
      switch (format) {
        case _ReceiptFormat.printPdf:
          await printReceipt(data);
        case _ReceiptFormat.sharePdf:
          await shareReceipt(data);
        case _ReceiptFormat.shareEscPos:
          await shareReceiptEscPos(data);
      }
    } catch (_) {
      if (mounted) showSnack(context, l10n.somethingWentWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sale = ref.watch(saleProvider(widget.saleId));
    final items = ref.watch(saleItemsProvider(widget.saleId));
    final payments = ref.watch(salePaymentsProvider(widget.saleId));
    final returns = ref.watch(saleReturnsProvider(widget.saleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saleDetail),
        actions: [
          IconButton(
            tooltip: l10n.printReceipt,
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _receipt(_ReceiptFormat.printPdf),
          ),
          PopupMenuButton<_ReceiptFormat>(
            tooltip: l10n.share,
            icon: const Icon(Icons.share_outlined),
            onSelected: _receipt,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ReceiptFormat.sharePdf,
                child: Text('${l10n.share} · PDF'),
              ),
              PopupMenuItem(
                value: _ReceiptFormat.shareEscPos,
                child: Text('${l10n.share} · ESC/POS'),
              ),
            ],
          ),
          if (sale.valueOrNull?.status == 'completed')
            IconButton(
              tooltip: l10n.returnItems,
              icon: const Icon(Icons.assignment_return_outlined),
              onPressed: () => context.push('${AppRoutes.sales}/${widget.saleId}/return'),
            ),
        ],
      ),
      body: sale.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is AppException ? error.message : l10n.somethingWentWrong),
        ),
        data: (s) {
          if (s == null) return Center(child: Text(l10n.productNotFound));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('${l10n.invoice}: ${s.invoiceNumber}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${l10n.status}: ${s.status}'),
              const Divider(height: 24),
              items.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (lines) => Column(
                  children: [
                    for (final line in lines)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(line.nameSnapshot),
                        subtitle: Text(
                          '${formatQty(line.qty)} × ${formatMoney(line.unitPrice)}',
                        ),
                        trailing: Text(formatMoney(line.lineTotal)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 24),
              _row(l10n.subtotal, formatMoney(s.subtotal)),
              if (s.discountTotal > Decimal.zero)
                _row(l10n.discount, formatMoney(s.discountTotal)),
              _row(l10n.tax, formatMoney(s.taxTotal)),
              _row(l10n.total, formatMoney(s.grandTotal), bold: true),
              _row(l10n.changeDue, formatMoney(s.changeDue)),
              const Divider(height: 24),
              Text(l10n.payments, style: Theme.of(context).textTheme.titleSmall),
              payments.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (rows) => Column(
                  children: [
                    for (final payment in rows)
                      _row(payment.method, formatMoney(payment.amount)),
                  ],
                ),
              ),
              returns.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (rows) => rows.isEmpty
                    ? const SizedBox.shrink()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          Text(l10n.returns, style: Theme.of(context).textTheme.titleSmall),
                          for (final r in rows)
                            _row(r.reason, '-${formatMoney(r.totalRefund)}'),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              if (s.status == 'completed')
                OutlinedButton.icon(
                  onPressed: _busy ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(l10n.cancelSale),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          ],
        ),
      );
}
