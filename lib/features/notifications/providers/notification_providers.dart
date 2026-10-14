import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/notification_item.dart';
import '../../../data/providers.dart';

class NotificationsController extends PagedController<AppNotification> {
  @override
  Future<List<AppNotification>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(notificationRepositoryProvider).fetchPage(offset: offset, limit: limit);
}

final notificationsControllerProvider =
    AutoDisposeAsyncNotifierProvider<NotificationsController, PagedState<AppNotification>>(
  NotificationsController.new,
);

final unreadNotificationsProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(notificationRepositoryProvider).unreadCount(),
);
