import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/audit_log.dart';
import '../../../data/providers.dart';

class AuditController extends PagedController<AuditLogEntry> {
  @override
  Future<List<AuditLogEntry>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(auditRepositoryProvider).fetchPage(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final auditControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuditController, PagedState<AuditLogEntry>>(
  AuditController.new,
);
