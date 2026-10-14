import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_exception.dart';
import '../models/category.dart';

class CatalogRepository {
  final SupabaseClient _client;

  const CatalogRepository(this._client);

  // --- Categories ---------------------------------------------------------
  Future<List<Category>> fetchCategories() async {
    try {
      final rows = await _client
          .from('categories')
          .select()
          .eq('status', 'active')
          .order('name', ascending: true);
      return rows.map((r) => Category.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Creates a category and returns its id (the product form types names
  /// directly and resolves them to rows on save).
  Future<String> createCategory({required String businessId, required String name}) async {
    try {
      final row = await _client
          .from('categories')
          .insert({'business_id': businessId, 'name': name.trim()})
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateCategory(String id, String name) async {
    try {
      await _client.from('categories').update({'name': name.trim()}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deactivateCategory(String id) async {
    try {
      await _client
          .from('categories')
          .update({'status': 'inactive', 'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Brands -------------------------------------------------------------
  Future<List<Brand>> fetchBrands() async {
    try {
      final rows = await _client.from('brands').select().eq('status', 'active').order('name', ascending: true);
      return rows.map((r) => Brand.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Creates a brand and returns its id (same free-text flow as categories).
  Future<String> createBrand({required String businessId, required String name}) async {
    try {
      final row = await _client
          .from('brands')
          .insert({'business_id': businessId, 'name': name.trim()})
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> updateBrand(String id, String name) async {
    try {
      await _client.from('brands').update({'name': name.trim()}).eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  Future<void> deactivateBrand(String id) async {
    try {
      await _client
          .from('brands')
          .update({'status': 'inactive', 'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw AppException.from(e);
    }
  }

  // --- Units --------------------------------------------------------------
  Future<List<Unit>> fetchUnits() async {
    try {
      final rows = await _client.from('units').select().eq('status', 'active').order('name', ascending: true);
      return rows.map((r) => Unit.fromMap(Map<String, dynamic>.from(r))).toList();
    } catch (e) {
      throw AppException.from(e);
    }
  }

  /// Creates a business-scoped unit from the product form's free-text field
  /// and returns its id. The stable `key` is derived from the name
  /// ("Kilogram" → "kilogram"); a collision with an existing key surfaces
  /// the DB's unique-violation message, which is honest enough.
  Future<String> createUnit({required String businessId, required String name}) async {
    try {
      final clean = name.trim();
      final key = clean.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      final row = await _client
          .from('units')
          .insert({
            'business_id': businessId,
            'key': key,
            'name': clean,
            'abbreviation':
                clean.length <= 4 ? clean.toLowerCase() : key.substring(0, 4),
            'decimals_allowed': 0,
            'is_system': false,
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw AppException.from(e);
    }
  }
}
