import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/notification_item.dart';

/// In-app notifications (SPEC §19, §63).
class NotificationRepository {
  final SupabaseClient _client;

  const NotificationRepository(this._client);

  static const int pageSize = 50;

  Future<List<AppNotification>> fetchPage({
    int offset = 0,
    int limit = pageSize,
  }) async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) => AppNotification.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<int> unreadCount() async {
    try {
      final rows = await _client
          .from('notifications')
          .select('id')
          .eq('is_read', false)
          .limit(100);
      return rows.length;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> markAllRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await _client.from('notifications').update({'is_read': true}).inFilter('id', ids);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
