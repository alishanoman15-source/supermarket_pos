import 'package:decimal/decimal.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/customer.dart';
import '../models/loyalty.dart';
import '../models/supplier.dart';

/// Suppliers, customers and the loyalty ledger (SPEC §69, §70).
/// Writes go straight to the tables; RLS + permission checks guard the rows.
class PartiesRepository {
  final SupabaseClient _client;

  const PartiesRepository(this._client);

  static const int pageSize = 50;

  // --- Suppliers ------------------------------------------------------------
  Future<List<Supplier>> fetchSuppliers({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('suppliers').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,phone.ilike.%$term%,email.ilike.%$term%');
      }
      final rows = await request
          .isFilter('deleted_at', null)
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);
      return rows.map((r) => Supplier.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Supplier?> fetchSupplier(String id) async {
    try {
      final row = await _client.from('suppliers').select().eq('id', id).maybeSingle();
      return row == null ? null : Supplier.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> saveSupplier({
    String? id,
    required String businessId,
    required Map<String, dynamic> values,
  }) async {
    try {
      if (id == null) {
        await _client.from('suppliers').insert({'business_id': businessId, ...values});
      } else {
        await _client.from('suppliers').update(values).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> archiveSupplier(String id) async {
    try {
      await _client.from('suppliers').update({
        'status': 'inactive',
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<SupplierPayment>> fetchSupplierPayments(String supplierId, {int limit = 50}) async {
    try {
      final rows = await _client
          .from('supplier_payments')
          .select()
          .eq('supplier_id', supplierId)
          .order('paid_at', ascending: false)
          .limit(limit);
      return rows.map((r) => SupplierPayment.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Pay a supplier (optionally against a specific bill) — SPEC §77.
  Future<void> paySupplier({
    required String supplierId,
    required Decimal amount,
    required String method,
    String? purchaseId,
    String? reference,
    String? note,
    String? idempotencyKey,
  }) async {
    try {
      await _client.rpc('pay_supplier', params: {
        'p_payload': {
          'supplier_id': supplierId,
          'purchase_id': purchaseId,
          'amount': amount.toString(),
          'method': method,
          if (reference != null && reference.isNotEmpty) 'reference': reference,
          if (note != null && note.isNotEmpty) 'note': note,
          'idempotency_key': idempotencyKey,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Customers ------------------------------------------------------------
  Future<List<Customer>> fetchCustomers({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client.from('customers').select();
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) {
        request = request.or('name.ilike.%$term%,phone.ilike.%$term%,email.ilike.%$term%');
      }
      final rows = await request
          .isFilter('deleted_at', null)
          .order('name', ascending: true)
          .range(offset, offset + limit - 1);
      return rows.map((r) => Customer.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<Customer?> fetchCustomer(String id) async {
    try {
      final row = await _client.from('customers').select().eq('id', id).maybeSingle();
      return row == null ? null : Customer.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> saveCustomer({
    String? id,
    required String businessId,
    required Map<String, dynamic> values,
  }) async {
    try {
      if (id == null) {
        await _client.from('customers').insert({'business_id': businessId, ...values});
      } else {
        await _client.from('customers').update(values).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> archiveCustomer(String id) async {
    try {
      await _client.from('customers').update({
        'status': 'inactive',
        'deleted_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<LoyaltyTransaction>> fetchLoyaltyTransactions(String customerId,
      {int limit = 100}) async {
    try {
      final rows = await _client
          .from('loyalty_transactions')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false)
          .limit(limit);
      return rows
          .map((r) => LoyaltyTransaction.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Redeem loyalty points (SPEC §70) — transactional RPC.
  Future<void> redeemLoyaltyPoints({
    required String customerId,
    required Decimal points,
    String? note,
  }) async {
    try {
      await _client.rpc('redeem_loyalty_points', params: {
        'p_payload': {
          'customer_id': customerId,
          'points': points.toString(),
          if (note != null && note.isNotEmpty) 'note': note,
        },
      });
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
