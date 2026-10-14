import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/audit_log.dart';

/// Append-only audit log reader (SPEC §27).
class AuditRepository {
  final SupabaseClient _client;

  const AuditRepository(this._client);

  static const int pageSize = 50;

  Future<List<AuditLogEntry>> fetchPage({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('audit_logs').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.ilike('action', '%$term%');
      final rows = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final entries = rows.map((r) => Map<String, dynamic>.from(r)).toList();
      final actorIds = entries
          .map((e) => e['actor_id'] as String?)
          .whereType<String>()
          .toSet();
      final names = await _actorNames(actorIds);

      return entries
          .map((e) => AuditLogEntry.fromMap({...e, 'actor_name': names[e['actor_id']]}))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Map<String, String>> _actorNames(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    try {
      final rows = await _client.from('profiles').select('id,name').inFilter('id', ids.toList());
      return {
        for (final r in rows) (r['id'] as String): (r['name'] as String?) ?? '',
      };
    } catch (_) {
      return const {};
    }
  }
}
