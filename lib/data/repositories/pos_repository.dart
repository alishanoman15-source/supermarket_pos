import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/money.dart';
import '../models/customer.dart';
import '../models/sale.dart';

/// POS sales: writes go through the transactional RPCs (SPEC §82), reads use
/// the RLS-guarded `sales` tables (SPEC §75–76).
class PosRepository {
  final SupabaseClient _client;

  const PosRepository(this._client);

  static const int pageSize = 50;

  // ---------------------------------------------------------------------------
  // Writes (RPC only)
  // ---------------------------------------------------------------------------

  Future<SaleResult> completeSale({
    required String branchId,
    required String shiftId,
    required String idempotencyKey,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
    String? customerId,
    String cartDiscount = '0',
    String? note,
  }) async {
    try {
      final res = await _client.rpc('complete_sale', params: {
        'p_payload': {
          'branch_id': branchId,
          'shift_id': shiftId,
          'idempotency_key': idempotencyKey,
          'items': items,
          'payments': payments,
          'cart_discount': cartDiscount,
          'customer_id': ?customerId,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      });
      final data = Map<String, dynamic>.from((res as Map)['data'] as Map);
      return SaleResult.fromMap(data);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> cancelSale({required String saleId, required String reason}) async {
    try {
      await _client.rpc('cancel_sale', params: {
        'p_sale_id': saleId,
        'p_reason': reason,
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> returnSale({
    required String saleId,
    required String reason,
    required List<Map<String, dynamic>> items,
    required String refundMethod,
    String? idempotencyKey,
  }) async {
    try {
      await _client.rpc('return_sale', params: {
        'p_payload': {
          'sale_id': saleId,
          'reason': reason,
          'refund_method': refundMethod,
          'items': items,
          'idempotency_key': ?idempotencyKey,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Reads
  // ---------------------------------------------------------------------------

  Future<List<Sale>> fetchSales({
    int offset = 0,
    int limit = pageSize,
    String? query,
    String? status,
  }) async {
    try {
      var request = _client.from('sales').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) {
        request = request.ilike('invoice_number', '%$term%');
      }
      if (status != null && status.isNotEmpty) {
        request = request.eq('status', status);
      }
      final rows = await request
          .order('sold_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) => Sale.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Sale?> fetchSale(String saleId) async {
    try {
      final row = await _client.from('sales').select().eq('id', saleId).maybeSingle();
      return row == null ? null : Sale.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<SaleItem>> fetchSaleItems(String saleId) async {
    try {
      final rows = await _client
          .from('sale_items')
          .select()
          .eq('sale_id', saleId)
          .order('created_at', ascending: true);
      return rows.map((r) => SaleItem.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<SalePayment>> fetchSalePayments(String saleId) async {
    try {
      final rows = await _client.from('sale_payments').select().eq('sale_id', saleId);
      return rows.map((r) => SalePayment.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<SaleReturn>> fetchSaleReturns(String saleId) async {
    try {
      final rows = await _client
          .from('sale_returns')
          .select()
          .eq('sale_id', saleId)
          .order('created_at', ascending: false);
      return rows.map((r) => SaleReturn.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Quantity already returned per `sale_item_id`, so the return form caps the
  /// selectable quantity at sold-minus-returned (SPEC §11).
  Future<Map<String, Decimal>> fetchReturnedQuantities(String saleId) async {
    try {
      final returns = await fetchSaleReturns(saleId);
      if (returns.isEmpty) return const {};
      final ids = returns.map((r) => r.id).toList();
      final rows = await _client
          .from('sale_return_items')
          .select('sale_item_id, qty')
          .inFilter('return_id', ids);
      final out = <String, Decimal>{};
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final itemId = map['sale_item_id'] as String;
        final qty = decimalFrom(map['qty']);
        out[itemId] = (out[itemId] ?? Decimal.zero) + qty;
      }
      return out;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Customer picker search (SPEC §15): phone/email/name.
  Future<List<Customer>> searchCustomers({String query = '', int limit = 30}) async {
    try {
      var request = _client.from('customers').select();
      final term = query.trim();
      if (term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,phone.ilike.%$term%,email.ilike.%$term%');
      }
      final rows = await request.order('name', ascending: true).limit(limit);
      return rows.map((r) => Customer.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
