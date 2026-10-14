import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_codes.dart';
import '../models/import_record.dart';

/// Bulk import metadata (SPEC §20, §102). The parsing/commit runs in the
/// server-side `import-products` edge function; this repository only records
/// jobs and reads their row-level results.
class ImportRepository {
  final SupabaseClient _client;

  const ImportRepository(this._client);

  static const int pageSize = 50;

  Future<List<ImportRecord>> fetchPage({int offset = 0, int limit = pageSize}) async {
    try {
      final rows = await _client
          .from('imports')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) => ImportRecord.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Calls the `import-products` edge function (SPEC §83, §102). Returns the
  /// parsed result: `{import_id, total_rows, valid_rows|imported, errors}`.
  Future<Map<String, dynamic>> _invokeImport({
    required String mode,
    required String csv,
    String? fileName,
  }) async {
    try {
      final res = await _client.functions.invoke('import-products', body: {
        'mode': mode,
        'csv': csv,
        'file_name': fileName,
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      final error = data is Map ? Map<String, dynamic>.from(data['error'] as Map? ?? const {}) : const {};
      throw AppException(
        (error['code'] as String?) ?? ErrorCode.internalError,
        (error['message'] as String?) ?? ErrorMessages.describe(data),
      );
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Validates a CSV without writing anything (preview → errors → confirm).
  Future<Map<String, dynamic>> previewImport({
    required String csv,
    String? fileName,
  }) =>
      _invokeImport(mode: 'preview', csv: csv, fileName: fileName);

  /// Commits a previously validated CSV.
  Future<Map<String, dynamic>> commitImport({
    required String csv,
    String? fileName,
  }) =>
      _invokeImport(mode: 'commit', csv: csv, fileName: fileName);

  /// Registers an uploaded file so the server worker can pick it up.
  Future<String> registerImport({
    required String businessId,
    required String kind,
    required String filePath,
    required String fileHash,
    required int totalRows,
  }) async {
    try {
      final row = await _client
          .from('imports')
          .insert({
            'business_id': businessId,
            'kind': kind,
            'file_path': filePath,
            'file_hash': fileHash,
            'total_rows': totalRows,
            'status': 'uploaded',
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
