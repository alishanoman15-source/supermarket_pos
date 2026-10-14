import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/paged_list.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/product_batch.dart';
import '../providers/inventory_providers.dart';

/// Batch / expiry view (SPEC §35): tracked batches with expiry warnings.
class BatchExpiryScreen extends ConsumerWidget {
  const BatchExpiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.batches)),
      body: PagedListView<ProductBatch>(
        provider: batchesControllerProvider,
        searchHint: l10n.batchNo,
        emptyMessage: l10n.noBatches,
        emptyIcon: Icons.event_note_outlined,
        itemBuilder: (context, batch) => ListTile(
          leading: Icon(
            batch.isExpired
                ? Icons.error_outline
                : batch.expiringSoon
                    ? Icons.warning_amber_outlined
                    : Icons.event_available_outlined,
            color: batch.isExpired
                ? Theme.of(context).colorScheme.error
                : batch.expiringSoon
                    ? Colors.orange
                    : null,
          ),
          title: Text(batch.productName),
          subtitle: Text([
            batch.batchNo ?? '—',
            if (batch.expiryDate != null) fmt.format(batch.expiryDate!),
          ].join(' · ')),
          trailing: Text(formatQty(batch.qty),
              style: Theme.of(context).textTheme.titleSmall),
        ),
      ),
    );
  }
}
