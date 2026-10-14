import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/expense.dart';

/// Expenses and expense categories (SPEC §17).
class ExpenseRepository {
  final SupabaseClient _client;

  const ExpenseRepository(this._client);

  static const int pageSize = 50;

  Future<List<Expense>> fetchExpenses({
    int offset = 0,
    int limit = pageSize,
    String? query,
  }) async {
    try {
      var request = _client
          .from('expenses')
          .select('*, category:expense_categories(name)');
      final term = query?.trim() ?? '';
      if (term.isNotEmpty) request = request.or('payee.ilike.%$term%,note.ilike.%$term%');
      final rows = await request
          .order('paid_at', ascending: false)
          .range(offset, offset + limit - 1);
      return rows.map((r) {
        final map = Map<String, dynamic>.from(r);
        final category = map['category'];
        if (category is Map) map['category_name'] = category['name'];
        return Expense.fromMap(map);
      }).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> saveExpense({
    String? id,
    required String businessId,
    required String branchId,
    required Map<String, dynamic> values,
  }) async {
    try {
      if (id == null) {
        await _client.from('expenses').insert({
          'business_id': businessId,
          'branch_id': branchId,
          ...values,
        });
      } else {
        await _client.from('expenses').update(values).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _client.from('expenses').update({'status': 'inactive'}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<List<ExpenseCategory>> fetchCategories() async {
    try {
      final rows = await _client.from('expense_categories').select().order('name', ascending: true);
      return rows.map((r) => ExpenseCategory.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> saveCategory({
    String? id,
    required String businessId,
    required String name,
  }) async {
    try {
      if (id == null) {
        await _client
            .from('expense_categories')
            .insert({'business_id': businessId, 'name': name.trim()});
      } else {
        await _client.from('expense_categories').update({'name': name.trim()}).eq('id', id);
      }
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _client.from('expense_categories').delete().eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
