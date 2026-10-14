import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/local/offline_database.dart';
import '../../../data/providers.dart';
import '../providers/sync_providers.dart';

/// Offline-sale sync status (SPEC §62): every locally queued sale with its
/// state, attempt count and last error, plus manual "sync now" / "retry all"
/// controls so a cashier can force an upload after connectivity returns.
class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    final l10n = context.l10n;
    try {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.syncRequested)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final queue = ref.watch(syncQueueProvider);
    final repo = ref.watch(offlineSyncRepositoryProvider);
    final scheme = Theme.of(context).colorScheme;
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncStatus)),
      body: AsyncView<List<SyncQueueData>>(
        value: queue,
        onRetry: () => ref.invalidate(syncQueueProvider),
        builder: (rows) {
          final waiting = rows.where((r) => r.status == 'pending').length;
          final blocked = rows.where((r) => r.status == 'blocked').length;
          final synced = rows.where((r) => r.status == 'synced').length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                l10n.syncOfflineHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              KpiGrid(
                children: [
                  KpiTile(
                    label: l10n.syncWaiting,
                    value: '$waiting',
                    icon: Icons.schedule_outlined,
                    accent: waiting > 0 ? Colors.orange : scheme.primary,
                  ),
                  KpiTile(
                    label: l10n.syncBlocked,
                    value: '$blocked',
                    icon: Icons.error_outline,
                    accent: scheme.error,
                  ),
                  KpiTile(
                    label: l10n.syncSynced,
                    value: '$synced',
                    icon: Icons.cloud_done_outlined,
                    accent: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (rows.isEmpty)
                EmptyState(
                  message: l10n.syncQueueEmpty,
                  icon: Icons.cloud_done_outlined,
                )
              else ...[
                Text(
                  l10n.syncQueuedSales,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (final row in rows)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              StatusChip(status: row.status),
                              const Spacer(),
                              Text(
                                dt.format(row.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DetailRow(
                            label: l10n.syncAttempts,
                            value: '${row.attempts}',
                          ),
                          if (row.lastError != null)
                            DetailRow(
                              label: l10n.syncLastError,
                              value: row.lastError!,
                            ),
                          Text(
                            row.idempotencyKey,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _canRetry(queue)
                    ? () => _run(context, ref, repo.retryFailedSales)
                    : null,
                icon: const Icon(Icons.replay_outlined),
                label: Text(l10n.syncRetryAll),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _run(context, ref, repo.syncPendingSales),
                icon: const Icon(Icons.sync_outlined),
                label: Text(l10n.syncSyncNow),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retry only makes sense once at least one sale is marked `blocked`
  /// (SPEC §62: pending → syncing → synced | failed, retry clears `failed`).
  bool _canRetry(AsyncValue<List<SyncQueueData>> queue) {
    final rows = queue.valueOrNull;
    if (rows == null) return false;
    return rows.any((r) => r.status == 'blocked');
  }
}
