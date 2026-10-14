import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/providers.dart';
import '../providers/notification_providers.dart';

/// Notifications inbox (SPEC §8, §63).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconFor(String type) {
    switch (type) {
      case 'LOW_STOCK':
        return Icons.trending_down;
      case 'OUT_OF_STOCK':
        return Icons.remove_shopping_cart_outlined;
      case 'EXPIRING_SOON':
      case 'EXPIRED':
        return Icons.event_busy_outlined;
      case 'SHIFT_VARIANCE':
        return Icons.account_balance_wallet_outlined;
      case 'SYNC_FAILED':
        return Icons.sync_problem_outlined;
      case 'REFUND_LARGE':
        return Icons.replay_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dt = DateFormat.yMMMd().add_Hm();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          IconButton(
            tooltip: l10n.markAllRead,
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              final page = ref.read(notificationsControllerProvider).valueOrNull;
              if (page == null) return;
              final ids = page.items.where((n) => !n.isRead).map((n) => n.id).toList();
              try {
                await ref.read(notificationRepositoryProvider).markAllRead(ids);
                ref.invalidate(notificationsControllerProvider);
                ref.invalidate(unreadNotificationsProvider);
              } on AppException catch (e) {
                if (context.mounted) showSnack(context, e.message);
              }
            },
          ),
        ],
      ),
      body: PagedListView<AppNotification>(
        provider: notificationsControllerProvider,
        emptyMessage: l10n.noNotifications,
        emptyIcon: Icons.notifications_none,
        itemBuilder: (context, notification) => ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Theme.of(context).colorScheme.primaryContainer,
            child: Icon(_iconFor(notification.type)),
          ),
          title: Text(
            notification.title,
            style: notification.isRead
                ? null
                : const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text([
            if (notification.body?.isNotEmpty == true) notification.body!,
            dt.format(notification.createdAt),
          ].join('\n')),
          isThreeLine: notification.body?.isNotEmpty == true,
          trailing: notification.isRead
              ? null
              : const Icon(Icons.circle, size: 10, color: Colors.teal),
          onTap: () async {
            if (notification.isRead) return;
            try {
              await ref.read(notificationRepositoryProvider).markRead(notification.id);
              ref.invalidate(notificationsControllerProvider);
              ref.invalidate(unreadNotificationsProvider);
            } on AppException catch (e) {
              if (context.mounted) showSnack(context, e.message);
            }
          },
        ),
      ),
    );
  }
}
