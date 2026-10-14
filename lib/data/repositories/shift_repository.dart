import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/shift.dart';

/// Shifts and drawer movements. All writes go through RPCs (SPEC §14, §82).
class ShiftRepository {
  final SupabaseClient _client;

  const ShiftRepository(this._client);

  Future<List<Shift>> fetchShifts({int limit = 50}) async {
    try {
      final rows = await _client
          .from('pos_shifts')
          .select()
          .order('opened_at', ascending: false)
          .limit(limit);
      return rows.map((r) => Shift.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<CashMovement>> fetchCashMovements(String shiftId) async {
    try {
      final rows = await _client
          .from('cash_movements')
          .select()
          .eq('shift_id', shiftId)
          .order('created_at', ascending: true)
          .limit(200);
      return rows.map((r) => CashMovement.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<String> openShift({required Decimal openingFloat}) async {
    try {
      final res = await _client.rpc('open_shift', params: {
        'p_payload': {'opening_float': openingFloat.toString()},
      });
      return Map<String, dynamic>.from((res as Map)['data'])['shift_id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> closeShift({
    required String shiftId,
    required Decimal counted,
    String? varianceReason,
  }) async {
    try {
      await _client.rpc('close_shift', params: {
        'p_payload': {
          'shift_id': shiftId,
          'closing_counted': counted.toString(),
          if (varianceReason != null && varianceReason.isNotEmpty) 'variance_reason': varianceReason,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> recordCashMovement({
    required String shiftId,
    required String type, // drawer_in | drawer_out
    required Decimal amount,
    String? note,
  }) async {
    try {
      await _client.rpc('record_cash_movement', params: {
        'p_payload': {
          'shift_id': shiftId,
          'type': type,
          'amount': amount.toString(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
