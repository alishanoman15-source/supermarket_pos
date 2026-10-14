import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/audit_log.dart';
import '../providers/audit_providers.dart';

/// Audit log viewer (SPEC §27). Read-only; requires `audit.view`.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.auditLog)),
      body: PagedListView<AuditLogEntry>(
        provider: auditControllerProvider,
        searchHint: l10n.action,
        emptyMessage: l10n.noAuditLogs,
        emptyIcon: Icons.history_outlined,
        itemBuilder: (context, entry) => ListTile(
          leading: AuditActionBadge(action: entry.action),
          title: Text(entry.action),
          subtitle: Text([
            if (entry.actorName?.isNotEmpty == true) entry.actorName!,
            if (entry.tableName != null) entry.tableName!,
            dt.format(entry.createdAt),
          ].join(' · ')),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => AuditDetailSheet(entry: entry),
          ),
        ),
      ),
    );
  }
}

/// Icon + tint for an audit action, so categories are scannable at a glance.
class AuditActionBadge extends StatelessWidget {
  final String action;

  const AuditActionBadge({super.key, required this.action});

  (IconData, Color) _style(ColorScheme scheme) {
    if (action.startsWith('user.')) return (Icons.person_outline, scheme.primary);
    if (action.startsWith('business.')) {
      return (Icons.storefront_outlined, scheme.tertiary);
    }
    if (action.startsWith('role') || action.contains('permission')) {
      return (Icons.admin_panel_settings_outlined, scheme.secondary);
    }
    if (action.startsWith('product.') || action.contains('price')) {
      return (Icons.sell_outlined, Colors.green.shade700);
    }
    if (action.startsWith('stock') ||
        action.startsWith('inventory') ||
        action.startsWith('purchase')) {
      return (Icons.warehouse_outlined, Colors.orange.shade700);
    }
    if (action.startsWith('sale') || action.startsWith('pos')) {
      return (Icons.receipt_long_outlined, scheme.primary);
    }
    return (Icons.history_outlined, scheme.onSurfaceVariant);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, tint) = _style(scheme);
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 20, color: tint),
    );
  }
}

/// Bottom-sheet detail for one audit entry: who/what/when plus a readable
/// Before / After breakdown (never a raw JSON blob, and never the price
/// labels that only suit `price_change` entries).
class AuditDetailSheet extends StatelessWidget {
  final AuditLogEntry entry;

  const AuditDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dt = DateFormat.yMMMd().add_Hm();
    final before = entry.beforeData;
    final after = entry.afterData;
    final hasChanges = before != null || after != null;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuditActionBadge(action: entry.action),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.action,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (entry.actorName?.isNotEmpty == true)
                          entry.actorName!,
                        if (entry.tableName != null) entry.tableName!,
                        dt.format(entry.createdAt),
                      ].join(' · '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!hasChanges)
            Text(
              l10n.auditNoChanges,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            )
          else ...[
            Text(l10n.auditChanges,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            if (before != null)
              _ChangeCard(
                label: l10n.auditBefore,
                data: before,
                tone: Colors.orange.shade700,
                icon: Icons.remove_circle_outline,
              ),
            if (before != null && after != null) const SizedBox(height: 12),
            if (after != null)
              _ChangeCard(
                label: l10n.auditAfter,
                data: after,
                tone: Colors.green.shade700,
                icon: Icons.check_circle_outline,
              ),
          ],
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final String label;
  final Map<String, dynamic> data;
  final Color tone;
  final IconData icon;

  const _ChangeCard({
    required this.label,
    required this.data,
    required this.tone,
    required this.icon,
  });

  static const _encoder = JsonEncoder.withIndent('  ');

  static String _prettyKey(String key) => key
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static bool _nested(Object? value) => value is Map || value is List;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tone),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: tone,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final entry in data.entries) ...[
            if (_nested(entry.value)) ...[
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                child: Text(
                  _prettyKey(entry.key),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _encoder.convert(entry.value),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DetailRow(
                  label: _prettyKey(entry.key),
                  value: entry.value == null ||
                          (entry.value is String && (entry.value as String).isEmpty)
                      ? '—'
                      : entry.value.toString(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
