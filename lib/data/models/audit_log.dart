/// An append-only audit entry (SPEC §27). Table `audit_logs`.
class AuditLogEntry {
  final String id;
  final String? actorId;
  final String? actorName;
  final String action;
  final String? tableName;
  final String? rowId;
  final Map<String, dynamic>? beforeData;
  final Map<String, dynamic>? afterData;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.createdAt,
    this.actorId,
    this.actorName,
    this.tableName,
    this.rowId,
    this.beforeData,
    this.afterData,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) => AuditLogEntry(
        id: map['id'] as String,
        actorId: map['actor_id'] as String?,
        actorName: map['actor_name'] as String?,
        action: (map['action'] as String?) ?? '',
        tableName: map['table_name'] as String?,
        rowId: map['row_id'] as String?,
        beforeData: map['before_data'] == null
            ? null
            : Map<String, dynamic>.from(map['before_data'] as Map),
        afterData: map['after_data'] == null
            ? null
            : Map<String, dynamic>.from(map['after_data'] as Map),
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
      );
}
