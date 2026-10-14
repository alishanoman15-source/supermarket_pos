/// Metadata for a bulk import job (SPEC §20, §102). Table `imports`.
class ImportRecord {
  final String id;
  final String kind;
  final String? filePath;
  final String? fileHash;
  final String status;
  final int totalRows;
  final int okRows;
  final int errorRows;
  final List<dynamic> errors;
  final DateTime createdAt;
  final DateTime? completedAt;

  const ImportRecord({
    required this.id,
    required this.kind,
    required this.status,
    required this.totalRows,
    required this.okRows,
    required this.errorRows,
    required this.errors,
    required this.createdAt,
    this.filePath,
    this.fileHash,
    this.completedAt,
  });

  factory ImportRecord.fromMap(Map<String, dynamic> map) => ImportRecord(
        id: map['id'] as String,
        kind: (map['kind'] as String?) ?? 'products',
        filePath: map['file_path'] as String?,
        fileHash: map['file_hash'] as String?,
        status: (map['status'] as String?) ?? 'uploaded',
        totalRows: (map['total_rows'] as num?)?.toInt() ?? 0,
        okRows: (map['ok_rows'] as num?)?.toInt() ?? 0,
        errorRows: (map['error_rows'] as num?)?.toInt() ?? 0,
        errors: (map['errors'] as List?) ?? const [],
        createdAt: map['created_at'] == null
            ? DateTime.now()
            : DateTime.parse(map['created_at'] as String).toLocal(),
        completedAt: map['completed_at'] == null
            ? null
            : DateTime.parse(map['completed_at'] as String).toLocal(),
      );
}
