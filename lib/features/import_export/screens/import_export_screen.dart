import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../core/utils/csv.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/share_file.dart';
import '../../../core/utils/xlsx.dart';
import '../../../data/models/import_record.dart';
import '../../../data/providers.dart';
import '../../reports/export/report_pdf.dart';

class ImportHistoryController extends PagedController<ImportRecord> {
  @override
  Future<List<ImportRecord>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(importRepositoryProvider).fetchPage(offset: offset, limit: limit);
}

final importHistoryControllerProvider =
    AutoDisposeAsyncNotifierProvider<ImportHistoryController, PagedState<ImportRecord>>(
  ImportHistoryController.new,
);

/// Import / Export center (SPEC §63, §64). Imports run through the server-side
/// `import-products` worker — validate → preview → confirm; exports are built
/// on the device and handed to the platform share sheet.
class ImportExportScreen extends ConsumerWidget {
  const ImportExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final history = ref.watch(importHistoryControllerProvider);
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.importExport)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ExportSection(),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.importCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.importProducts, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  l10n.downloadTemplate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                const _ImportSection(),
                const SizedBox(height: 16),
                history.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(e is AppException ? e.message : l10n.somethingWentWrong),
                  data: (page) => page.items.isEmpty
                      ? Text(l10n.noImports)
                      : Column(
                          children: [
                            for (final record in page.items)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.upload_file_outlined),
                                title: Text('${record.kind} · ${record.totalRows}'),
                                subtitle: Text(
                                  '${dt.format(record.createdAt)} · '
                                  '${l10n.count}: ${record.okRows}/${record.totalRows}',
                                ),
                                trailing: StatusChip(status: record.status),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Export (SPEC §64)
// ---------------------------------------------------------------------------

class _ExportSection extends ConsumerStatefulWidget {
  const _ExportSection();

  @override
  ConsumerState<_ExportSection> createState() => _ExportSectionState();
}

/// Export file format offered by the export center (SPEC §64: CSV/XLSX/PDF).
enum _ExportFormat { csv, excel }

class _ExportSectionState extends ConsumerState<_ExportSection> {
  static const int _exportLimit = 1000;
  String? _busy;
  _ExportFormat _format = _ExportFormat.csv;

  /// Shares one table in the currently selected format.
  Future<void> _shareTable({
    required String fileName,
    required List<Object?> headers,
    required List<List<Object?>> rows,
  }) {
    if (_format == _ExportFormat.excel) {
      return shareXlsxFile(
        fileName: fileName.replaceAll('.csv', '.xlsx'),
        bytes: buildXlsx(sheetName: fileName.split('.').first, headers: headers, rows: rows),
      );
    }
    return shareCsvFile(fileName: fileName, csv: csvFile(headers, rows));
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      await action();
      if (mounted) showSnack(context, context.l10n.exportStarted);
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _exportProducts() async {
    final items = await ref
        .read(productRepositoryProvider)
        .fetchPage(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'products.csv',
      headers: const [
          'name',
          'sku',
          'barcode',
          'purchase_price',
          'selling_price',
          'tax_rate',
          'reorder_level',
          'stock',
          'status',
        ],
      rows: [
          for (final p in items)
            [
              p.name,
              p.sku,
              p.barcode,
              p.purchasePrice,
              p.sellingPrice,
              p.taxRate,
              p.reorderLevel,
              p.stock,
              p.status,
            ],
        ],
    );
  }

  Future<void> _exportInventory() async {
    final items =
        await ref.read(inventoryRepositoryProvider).fetchOnHand(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'inventory.csv',
      headers: const [
          'name',
          'sku',
          'barcode',
          'on_hand',
          'reserved',
          'reorder_level',
          'status',
        ],
      rows: [
          for (final r in items)
            [r.name, r.sku, r.barcode, r.onHand, r.reserved, r.reorderLevel, r.status],
        ],
    );
  }

  Future<void> _exportSales() async {
    final items =
        await ref.read(posRepositoryProvider).fetchSales(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'sales.csv',
      headers: const [
          'invoice_number',
          'sold_at',
          'subtotal',
          'discount',
          'tax',
          'total',
          'amount_paid',
          'status',
        ],
      rows: [
          for (final s in items)
            [
              s.invoiceNumber,
              s.soldAt.toIso8601String(),
              s.subtotal,
              s.discountTotal,
              s.taxTotal,
              s.grandTotal,
              s.amountPaid,
              s.status,
            ],
        ],
    );
  }

  Future<void> _exportPurchases() async {
    final items =
        await ref.read(purchasingRepositoryProvider).fetchPurchases(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'purchases.csv',
      headers: const [
          'supplier',
          'bill_number',
          'received_at',
          'subtotal',
          'tax',
          'total',
          'paid',
          'status',
        ],
      rows: [
          for (final p in items)
            [
              p.supplierName,
              p.billNumber,
              p.receivedAt.toIso8601String(),
              p.subtotal,
              p.taxTotal,
              p.total,
              p.paidTotal,
              p.status,
            ],
        ],
    );
  }

  Future<void> _exportCustomers() async {
    final items =
        await ref.read(partiesRepositoryProvider).fetchCustomers(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'customers.csv',
      headers: const ['name', 'phone', 'email', 'loyalty_points', 'credit_limit'],
      rows: [
          for (final c in items)
            [c.name, c.phone, c.email, c.loyaltyPoints, c.creditLimit],
        ],
    );
  }

  Future<void> _exportSuppliers() async {
    final items =
        await ref.read(partiesRepositoryProvider).fetchSuppliers(offset: 0, limit: _exportLimit);
    await _shareTable(
      fileName: 'suppliers.csv',
      headers: const [
          'name',
          'contact_person',
          'phone',
          'email',
          'address',
          'opening_balance',
          'status',
        ],
      rows: [
          for (final s in items)
            [
              s.name,
              s.contactPerson,
              s.phone,
              s.email,
              s.address,
              s.openingBalance,
              s.status,
            ],
        ],
    );
  }

  Future<void> _exportProductsPdf() async {
    final l10n = context.l10n;
    final products =
        await ref.read(productRepositoryProvider).fetchPage(offset: 0, limit: _exportLimit);
    await shareReportPdf(ExportTable(
      title: l10n.products,
      subtitle: l10n.catalog,
      headers: [l10n.productName, l10n.sku, l10n.barcode, l10n.sellingPrice, l10n.stockOnHand],
      rows: [
        for (final p in products)
          [
            p.name,
            p.sku ?? '',
            p.barcode ?? '',
            money(p.sellingPrice),
            formatQty(p.stock),
          ],
      ],
    ));
  }

  Widget _button({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: _busy != null && onPressed == null
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = _busy != null;
    final csvLabel = _format == _ExportFormat.csv ? l10n.exportCsv : l10n.exportExcel;
    return SectionCard(
      title: l10n.exportData,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<_ExportFormat>(
            segments: [
              ButtonSegment(value: _ExportFormat.csv, label: Text(l10n.exportCsv)),
              ButtonSegment(value: _ExportFormat.excel, label: Text(l10n.exportExcel)),
            ],
            selected: {_format},
            onSelectionChanged: busy
                ? null
                : (selection) => setState(() => _format = selection.first),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _button(
                label: '${l10n.products} · $csvLabel',
                icon: Icons.inventory_2_outlined,
                onPressed: busy ? null : () => _run('products', _exportProducts),
              ),
              _button(
                label: '${l10n.inventory} · $csvLabel',
                icon: Icons.warehouse_outlined,
                onPressed: busy ? null : () => _run('inventory', _exportInventory),
              ),
              _button(
                label: '${l10n.sales} · $csvLabel',
                icon: Icons.receipt_long_outlined,
                onPressed: busy ? null : () => _run('sales', _exportSales),
              ),
              _button(
                label: '${l10n.purchases} · $csvLabel',
                icon: Icons.local_shipping_outlined,
                onPressed: busy ? null : () => _run('purchases', _exportPurchases),
              ),
              _button(
                label: '${l10n.customers} · $csvLabel',
                icon: Icons.people_outline,
                onPressed: busy ? null : () => _run('customers', _exportCustomers),
              ),
              _button(
                label: '${l10n.suppliers} · $csvLabel',
                icon: Icons.factory_outlined,
                onPressed: busy ? null : () => _run('suppliers', _exportSuppliers),
              ),
              _button(
                label: '${l10n.products} · ${l10n.exportPdf}',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: busy ? null : () => _run('productsPdf', _exportProductsPdf),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Import (SPEC §63: upload → validate → errors → preview → confirm)
// ---------------------------------------------------------------------------

class _ImportSection extends ConsumerStatefulWidget {
  const _ImportSection();

  @override
  ConsumerState<_ImportSection> createState() => _ImportSectionState();
}

class _ImportSectionState extends ConsumerState<_ImportSection> {
  /// Column names the `import-products` worker understands (SPEC §63).
  static const String template =
      'name,sku,barcode,category,brand,purchase_price,selling_price,tax_rate,reorder_level\n'
      'Basmati Rice 5 kg,RICE-001,8901234567890,Groceries,Rice Mill,1200,1450,0,10\n'
      'Cola 1.5 L,COLA-001,8901234567891,Beverages,Cola Co,140,180,0,12\n';

  bool _busy = false;

  Future<void> _guard(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } catch (_) {
      if (mounted) showSnack(context, context.l10n.somethingWentWrong);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFile() => _guard(() async {
        final files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['csv', 'txt', 'xlsx'],
        );
        if (files.isEmpty) return;
        final file = files.first;
        final bytes = await file.readAsBytes();
        // Excel workbooks are converted to CSV here; the server-side worker
        // parses CSV only (SPEC §20 accepts CSV/XLSX uploads).
        final isXlsx = file.name.toLowerCase().endsWith('.xlsx');
        final csv = isXlsx
            ? xlsxToCsv(bytes)
            : utf8.decode(bytes, allowMalformed: true);
        await _preview(csv, file.name);
      });

  Future<void> _pasteCsv() async {
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.pasteCsv),
        content: SizedBox(
          width: 520,
          child: AppTextField(
            controller: controller,
            label: context.l10n.pasteCsv,
            maxLines: 10,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.preview),
          ),
        ],
      ),
    );
    final csv = controller.text;
    controller.dispose();
    if (submitted != true) return;
    await _guard(() => _preview(csv, null));
  }

  Future<void> _showTemplate() async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.downloadTemplate),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(
              template,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: template));
              if (context.mounted) {
                Navigator.pop(context);
                showSnack(context, l10n.copied);
              }
            },
            icon: const Icon(Icons.copy_outlined),
            label: Text(l10n.copy),
          ),
        ],
      ),
    );
  }

  /// Step 1+2: send the file for server-side validation and show the result.
  Future<void> _preview(String csv, String? fileName) async {
    if (csv.trim().isEmpty) {
      showSnack(context, context.l10n.emptyFile);
      return;
    }
    final repo = ref.read(importRepositoryProvider);
    final preview = await repo.previewImport(csv: csv, fileName: fileName);
    if (!mounted) return;

    final total = (preview['total_rows'] as num?)?.toInt() ?? 0;
    final valid = (preview['valid_rows'] as num?)?.toInt() ?? 0;
    final errors = _rows(preview['errors']);
    final samples = _rows(preview['preview']);
    final proceed = await _showValidation(total, valid, errors, samples);
    if (proceed != true || !mounted) return;
    if (valid == 0) {
      showSnack(context, context.l10n.noValidRows);
      return;
    }

    final result = await repo.commitImport(csv: csv, fileName: fileName);
    ref.invalidate(importHistoryControllerProvider);
    if (!mounted) return;
    await _showResult(
      (result['imported'] as num?)?.toInt() ?? 0,
      _rows(result['errors']),
    );
  }

  Future<bool> _showValidation(
    int total,
    int valid,
    List<Map<String, dynamic>> errors,
    List<Map<String, dynamic>> samples,
  ) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.preview),
        content: SizedBox(
          width: 520,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.rows}: $total'),
              Text('${l10n.validRows}: $valid'),
              Text('${l10n.errorRows}: ${errors.length}'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (samples.isNotEmpty) ...[
                      Text(l10n.preview, style: Theme.of(context).textTheme.labelLarge),
                      for (final row in samples)
                        Text(
                          '${row['name'] ?? ''} ${row['sku'] ?? ''} '
                          '${row['selling_price'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                    ],
                    if (errors.isNotEmpty) ...[
                      Text(l10n.errors, style: Theme.of(context).textTheme.labelLarge),
                      for (final error in errors)
                        Text(
                          '${error['row']}: ${error['field']} — ${error['message']}',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: valid > 0 ? () => Navigator.pop(context, true) : null,
            child: Text(l10n.importNow),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showResult(int imported, List<Map<String, dynamic>> errors) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importProducts),
        content: SizedBox(
          width: 520,
          height: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${l10n.imported}: $imported'),
              Text('${l10n.errorRows}: ${errors.length}'),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    for (final error in errors)
                      Text(
                        '${error['row']}: ${error['field']} — ${error['message']}',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _rows(Object? value) => [
        for (final row in value is List ? value : const [])
          if (row is Map) Map<String, dynamic>.from(row),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : _pickFile,
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(l10n.chooseFile),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _pasteCsv,
          icon: const Icon(Icons.paste_outlined),
          label: Text(l10n.pasteCsv),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _busy ? null : _showTemplate,
          icon: const Icon(Icons.download_outlined),
          label: Text(l10n.downloadTemplate),
        ),
      ],
    );
  }
}
