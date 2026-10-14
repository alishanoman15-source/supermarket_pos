import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/platform/io_compat.dart';
import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/product.dart' as models;
import '../models/shift.dart' as models;
import '../local/offline_database.dart';

class OfflineOrderSubmission {
  final String localOrderId;
  final String idempotencyKey;
  final String? serverSaleId;
  final String? invoiceNumber;
  final String status;

  const OfflineOrderSubmission({
    required this.localOrderId,
    required this.idempotencyKey,
    required this.status,
    this.serverSaleId,
    this.invoiceNumber,
  });

  bool get isSynced => serverSaleId != null;
  bool get needsReview => status == 'sync_conflict';
}

/// Offline-first write path for POS sales. It persists the local order and its
/// RPC payload atomically, then syncs FIFO through the sales RPCs.
class OfflineSyncRepository {
  final OfflineDatabase _database;
  final SupabaseClient _client;
  final Connectivity _connectivity;
  final Uuid _uuid;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AuthState>? _authSubscription;
  Future<void>? _activeSync;
  bool _syncRequested = false;

  OfflineSyncRepository(
    this._database,
    this._client, {
    Connectivity? connectivity,
    Uuid? uuid,
  }) : _connectivity = connectivity ?? Connectivity(),
       _uuid = uuid ?? const Uuid();

  void start() {
    _connectivitySubscription ??= _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      if (_hasNetwork(results)) unawaited(_syncAfterConnectivityChange());
    });
    _authSubscription ??= _client.auth.onAuthStateChange.listen((_) {
      unawaited(_syncAfterConnectivityChange());
    });
    unawaited(_syncAfterConnectivityChange());
  }

  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    await _authSubscription?.cancel();
  }

  Future<void> cacheCategories(
    String businessId,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final now = DateTime.now().toUtc();
    await _database.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _database.categories,
          CategoriesCompanion.insert(
            id: row['id'] as String,
            businessId: businessId,
            name: row['name'] as String,
            parentId: Value(row['parent_id'] as String?),
            status: Value((row['status'] as String?) ?? 'active'),
            createdAt: Value(_date(row['created_at'])),
            updatedAt: _date(row['updated_at']) ?? now,
            deletedAt: Value(_date(row['deleted_at'])),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> refreshCatalogIfStale({
    required String businessId,
    required String branchId,
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    final snapshot = await (_database.select(_database.catalogCacheStates)
          ..where((row) =>
              row.businessId.equals(businessId) &
              row.branchId.equals(branchId)))
        .getSingleOrNull();
    final now = DateTime.now().toUtc();
    if (snapshot != null && now.difference(snapshot.syncedAt) < maxAge) return;

    final categories = await _client
        .from('categories')
        .select('id,name,parent_id,status,updated_at,deleted_at')
        .eq('business_id', businessId);
    await cacheCategories(
      businessId,
      categories.map((row) => Map<String, dynamic>.from(row)),
    );

    const pageSize = 500;
    var offset = 0;
    while (true) {
      final rows = await _client
          .from('product_pos_view')
          .select()
          .eq('business_id', businessId)
          .order('name', ascending: true)
          .range(offset, offset + pageSize - 1);
      await cacheProducts(
        businessId,
        branchId,
        rows.map((row) => Map<String, dynamic>.from(row)),
      );
      if (rows.length < pageSize) break;
      offset += pageSize;
    }

    await _database.into(_database.catalogCacheStates).insertOnConflictUpdate(
          CatalogCacheStatesCompanion.insert(
            businessId: businessId,
            branchId: branchId,
            syncedAt: now,
          ),
        );
  }

  Future<void> cacheShifts(
    String profileId,
    String businessId,
    Iterable<models.Shift> shifts,
  ) async {
    final now = DateTime.now().toUtc();
    await _database.transaction(() async {
      await (_database.delete(_database.posShifts)
            ..where((row) => row.profileId.equals(profileId)))
          .go();
      await _database.batch((batch) {
        for (final shift in shifts) {
          batch.insert(
            _database.posShifts,
            PosShiftsCompanion.insert(
              id: shift.id,
              profileId: profileId,
              businessId: businessId,
              branchId: shift.branchId,
              status: shift.status,
              openingFloat: shift.openingFloat.toString(),
              closingCounted: Value(shift.closingCounted?.toString()),
              expectedCash: Value(shift.expectedCash?.toString()),
              variance: Value(shift.variance?.toString()),
              varianceReason: Value(shift.varianceReason),
              openedAt: shift.openedAt.toUtc(),
              closedAt: Value(shift.closedAt?.toUtc()),
              cachedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  Future<models.Shift?> cachedOpenShift(String profileId) async {
    final row = await (_database.select(_database.posShifts)
          ..where((shift) =>
              shift.profileId.equals(profileId) &
              shift.status.equals('open'))
          ..orderBy([(shift) => OrderingTerm.desc(shift.openedAt)]))
        .getSingleOrNull();
    return row == null
        ? null
        : models.Shift(
            id: row.id,
            branchId: row.branchId,
            status: row.status,
            openingFloat: Decimal.parse(row.openingFloat),
            closingCounted: row.closingCounted == null
                ? null
                : Decimal.parse(row.closingCounted!),
            expectedCash: row.expectedCash == null
                ? null
                : Decimal.parse(row.expectedCash!),
            variance:
                row.variance == null ? null : Decimal.parse(row.variance!),
            varianceReason: row.varianceReason,
            openedAt: row.openedAt.toLocal(),
            closedAt: row.closedAt?.toLocal(),
          );
  }

  Future<List<models.Category>> cachedCategories(String businessId) async {
    final rows =
        await (_database.select(_database.categories)
              ..where(
                (row) =>
                    row.businessId.equals(businessId) &
                    row.status.equals('active'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.name)]))
            .get();
    return rows
        .map(
          (row) => models.Category(
            id: row.id,
            businessId: row.businessId,
            name: row.name,
            status: row.status,
          ),
        )
        .toList();
  }

  Future<void> cacheProducts(
    String businessId,
    String branchId,
    Iterable<Map<String, dynamic>> rows,
  ) async {
    final now = DateTime.now().toUtc();
    await _database.batch((batch) {
      for (final row in rows) {
        batch.insert(
          _database.products,
          ProductsCompanion.insert(
            id: row['id'] as String,
            businessId: businessId,
            branchId: branchId,
            name: row['name'] as String,
            sku: Value(row['sku'] as String?),
            barcode: Value(row['barcode'] as String?),
            categoryId: Value(row['category_id'] as String?),
            brandId: Value(row['brand_id'] as String?),
            unitId: Value(row['unit_id'] as String?),
            sellingPrice: _decimalString(row['selling_price']),
            taxRate: _decimalString(row['tax_rate']),
            isWeightBased: row['is_weight_based'] as bool? ?? false,
            trackBatch: row['track_batch'] as bool? ?? false,
            reorderLevel: _decimalString(row['reorder_level']),
            stock: _decimalString(row['stock']),
            status: (row['status'] as String?) ?? 'active',
            imageUrl: Value(row['image_url'] as String?),
            description: Value(row['description'] as String?),
            createdAt: Value(_date(row['created_at'])),
            updatedAt: Value(_date(row['updated_at'])),
            deletedAt: Value(_date(row['deleted_at'])),
            cachedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<models.Product>> searchCachedProducts({
    required String businessId,
    required String branchId,
    String query = '',
    int limit = 50,
  }) async {
    final term = query.trim();
    final statement = _database.select(_database.products)
      ..where(
        (row) =>
            row.businessId.equals(businessId) &
            row.branchId.equals(branchId) &
            row.status.equals('active'),
      );
    if (term.isNotEmpty) {
      statement.where(
        (row) =>
            row.name.contains(term) |
            row.sku.contains(term) |
            row.barcode.equals(term),
      );
    }
    final rows =
        await (statement
              ..orderBy([(row) => OrderingTerm.asc(row.name)])
              ..limit(limit))
            .get();
    return rows.map(_productFromCache).toList();
  }

  Future<models.Product?> cachedProductByBarcode({
    required String businessId,
    required String branchId,
    required String barcode,
  }) async {
    final row =
        await (_database.select(_database.products)..where(
              (product) =>
                  product.businessId.equals(businessId) &
                  product.branchId.equals(branchId) &
                  product.barcode.equals(barcode) &
                  product.status.equals('active'),
            ))
            .getSingleOrNull();
    return row == null ? null : _productFromCache(row);
  }

  /// Persist first; if the RPC response is lost, the same key safely retries.
  Future<OfflineOrderSubmission> enqueueSale({
    required String businessId,
    required String branchId,
    required String shiftId,
    required String cashierId,
    required String idempotencyKey,
    required bool offlineMode,
    required String cartDiscount,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> payments,
    required List<Map<String, dynamic>> itemSnapshots,
    required String subtotal,
    required String discountTotal,
    required String taxTotal,
    required String grandTotal,
    required String amountPaid,
    required String changeDue,
    String? customerId,
    String? note,
  }) async {
    final localOrderId = _uuid.v4();
    final capturedAt = DateTime.now().toUtc();
    final rpcPayload = <String, dynamic>{
      'branch_id': branchId,
      'shift_id': shiftId,
      'idempotency_key': idempotencyKey,
      'offline_mode': offlineMode,
      'items': items,
      'payments': payments,
      'cart_discount': cartDiscount,
      'customer_id': ?customerId,
      if (note case final value? when value.isNotEmpty) 'note': value,
    };

    await _database.transaction(() async {
      await _database
          .into(_database.orders)
          .insert(
            OrdersCompanion.insert(
              id: localOrderId,
              businessId: businessId,
              branchId: branchId,
              shiftId: shiftId,
              cashierId: cashierId,
              customerId: Value(customerId),
              idempotencyKey: idempotencyKey,
              subtotal: subtotal,
              discountTotal: discountTotal,
              taxTotal: taxTotal,
              grandTotal: grandTotal,
              amountPaid: amountPaid,
              changeDue: changeDue,
              note: Value(note),
              rpcPayload: jsonEncode(rpcPayload),
              capturedAt: capturedAt,
              createdAt: Value(capturedAt),
            ),
          );
      for (final snapshot in itemSnapshots) {
        await _database
            .into(_database.orderItems)
            .insert(
              OrderItemsCompanion.insert(
                id: snapshot['id'] as String? ?? _uuid.v4(),
                orderId: localOrderId,
                productId: snapshot['product_id'] as String,
                batchId: Value(snapshot['batch_id'] as String?),
                nameSnapshot: snapshot['name_snapshot'] as String,
                skuSnapshot: Value(snapshot['sku_snapshot'] as String?),
                barcodeSnapshot: Value(snapshot['barcode_snapshot'] as String?),
                qty: _decimalString(snapshot['qty']),
                unitPrice: _decimalString(snapshot['unit_price']),
                costAtSale: Value(
                  snapshot['cost_at_sale'] == null
                      ? null
                      : _decimalString(snapshot['cost_at_sale']),
                ),
                discount: Value(_decimalString(snapshot['discount'])),
                taxRate: Value(_decimalString(snapshot['tax_rate'])),
                taxAmount: Value(
                  snapshot['tax_amount'] == null
                      ? null
                      : _decimalString(snapshot['tax_amount']),
                ),
                lineTotal: Value(
                  snapshot['line_total'] == null
                      ? null
                      : _decimalString(snapshot['line_total']),
                ),
                createdAt: Value(_date(snapshot['created_at'])),
              ),
            );
      }
      await _database
          .into(_database.syncQueue)
          .insert(
            SyncQueueCompanion.insert(
              idempotencyKey: idempotencyKey,
              orderId: localOrderId,
              businessId: businessId,
              cashierId: cashierId,
              payload: jsonEncode(rpcPayload),
              createdAt: capturedAt,
              updatedAt: capturedAt,
            ),
          );
    });

    if (!offlineMode) await syncPendingSales();
    final order = await (_database.select(
      _database.orders,
    )..where((row) => row.id.equals(localOrderId))).getSingle();
    return OfflineOrderSubmission(
      localOrderId: localOrderId,
      idempotencyKey: idempotencyKey,
      serverSaleId: order.serverSaleId,
      invoiceNumber: order.invoiceNumber,
      status: order.syncStatus,
    );
  }

  Future<void> syncPendingSales() {
    final running = _activeSync;
    if (running != null) {
      _syncRequested = true;
      return running;
    }

    final completer = Completer<void>();
    _activeSync = completer.future;
    Future<void>(() async {
      try {
        do {
          _syncRequested = false;
          await _syncPendingSales();
        } while (_syncRequested);
        completer.complete();
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _activeSync = null;
      }
    });
    return completer.future;
  }

  Future<void> retryFailedSales() async {
    await (_database.update(
      _database.syncQueue,
    )..where((row) => row.status.equals('blocked'))).write(
      SyncQueueCompanion(
        status: const Value('pending'),
        lastError: const Value(null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    await syncPendingSales();
  }

  Stream<List<SyncQueueData>> watchQueue() => (_database.select(
    _database.syncQueue,
  )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).watch();

  Future<void> _syncPendingSales() async {
    final cashierId = _client.auth.currentUser?.id;
    if (cashierId == null) return;

    final queued =
        await (_database.select(_database.syncQueue)
              ..where(
                (row) =>
                    row.cashierId.equals(cashierId) &
                    row.status.equals('pending'),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();

    for (final queuedSale in queued) {
      try {
        final payload = Map<String, dynamic>.from(
          jsonDecode(queuedSale.payload) as Map,
        );
        final offlineMode = payload['offline_mode'] as bool? ?? false;
        final response = await _client.rpc(
          offlineMode ? 'complete_offline_sale' : 'complete_sale',
          params: {'p_payload': payload},
        );
        final data = Map<String, dynamic>.from(
          (response as Map)['data'] as Map,
        );
        final serverSaleId = data['sale_id'] as String;
        var remoteSale = data;
        if (remoteSale['invoice_number'] == null ||
            remoteSale['grand_total'] == null) {
          final row = await _client
              .from('sales')
              .select()
              .eq('id', serverSaleId)
              .single();
          remoteSale = Map<String, dynamic>.from(row);
        }
        final remoteItems = await _client
            .from('sale_items')
            .select()
            .eq('sale_id', serverSaleId);

        final syncedAt = DateTime.now().toUtc();
        await _database.transaction(() async {
          await (_database.update(
            _database.orders,
          )..where((row) => row.id.equals(queuedSale.orderId))).write(
            OrdersCompanion(
              status: Value((remoteSale['status'] as String?) ?? 'completed'),
              syncStatus: const Value('synced'),
              serverSaleId: Value(serverSaleId),
              invoiceNumber: Value(remoteSale['invoice_number'] as String?),
              subtotal: Value(_decimalString(remoteSale['subtotal'])),
              discountTotal: Value(
                _decimalString(remoteSale['discount_total']),
              ),
              taxTotal: Value(_decimalString(remoteSale['tax_total'])),
              grandTotal: Value(_decimalString(remoteSale['grand_total'])),
              amountPaid: Value(_decimalString(remoteSale['amount_paid'])),
              changeDue: Value(_decimalString(remoteSale['change_due'])),
              syncedAt: Value(syncedAt),
              serverSoldAt: Value(_date(remoteSale['sold_at'])),
              serverCreatedAt: Value(_date(remoteSale['created_at'])),
            ),
          );
          final localItems = await (_database.select(
            _database.orderItems,
          )..where((row) => row.orderId.equals(queuedSale.orderId))).get();
          for (final remoteItem in remoteItems) {
            final productId = remoteItem['product_id'] as String;
            final matchingItems = localItems.where(
              (item) => item.productId == productId,
            );
            if (matchingItems.isEmpty) continue;
            final localItem = matchingItems.first;
            await (_database.update(
              _database.orderItems,
            )..where((row) => row.id.equals(localItem.id))).write(
              OrderItemsCompanion(
                serverItemId: Value(remoteItem['id'] as String),
                batchId: Value(remoteItem['batch_id'] as String?),
                nameSnapshot: Value(remoteItem['name_snapshot'] as String),
                skuSnapshot: Value(remoteItem['sku_snapshot'] as String?),
                barcodeSnapshot: Value(
                  remoteItem['barcode_snapshot'] as String?,
                ),
                qty: Value(_decimalString(remoteItem['qty'])),
                unitPrice: Value(_decimalString(remoteItem['unit_price'])),
                costAtSale: Value(_decimalString(remoteItem['cost_at_sale'])),
                discount: Value(_decimalString(remoteItem['discount'])),
                taxRate: Value(_decimalString(remoteItem['tax_rate'])),
                taxAmount: Value(_decimalString(remoteItem['tax_amount'])),
                lineTotal: Value(_decimalString(remoteItem['line_total'])),
                createdAt: Value(_date(remoteItem['created_at'])),
              ),
            );
          }
          await (_database.update(_database.syncQueue)..where(
                (row) => row.idempotencyKey.equals(queuedSale.idempotencyKey),
              ))
              .write(
                SyncQueueCompanion(
                  status: const Value('synced'),
                  lastError: const Value(null),
                  updatedAt: Value(syncedAt),
                ),
              );
        });
      } on IOException catch (error) {
        await _recordRetryableFailure(queuedSale, error);
        return;
      } on TimeoutException catch (error) {
        await _recordRetryableFailure(queuedSale, error);
        return;
      } on PostgrestException catch (error) {
        await _recordBlockedFailure(queuedSale, error);
        return;
      }
    }
  }

  Future<void> _recordRetryableFailure(SyncQueueData sale, Object error) async {
    final payload = Map<String, dynamic>.from(jsonDecode(sale.payload) as Map);
    payload['offline_mode'] = true;
    final items = (payload['items'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    final localItems = await (_database.select(
      _database.orderItems,
    )..where((row) => row.orderId.equals(sale.orderId))).get();
    for (final item in items) {
      final productId = item['product_id'] as String;
      final matchingItems = localItems.where(
        (localItem) => localItem.productId == productId,
      );
      if (matchingItems.isNotEmpty) {
        item['unit_price'] = matchingItems.first.unitPrice;
      }
    }
    payload['items'] = items;
    final encodedPayload = jsonEncode(payload);
    final now = DateTime.now().toUtc();
    await _database.transaction(() async {
      await (_database.update(
        _database.syncQueue,
      )..where((row) => row.idempotencyKey.equals(sale.idempotencyKey))).write(
        SyncQueueCompanion(
          payload: Value(encodedPayload),
          attempts: Value(sale.attempts + 1),
          lastError: Value(error.toString()),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(_database.orders)
            ..where((row) => row.id.equals(sale.orderId)))
          .write(OrdersCompanion(rpcPayload: Value(encodedPayload)));
    });
  }

  Future<void> _recordBlockedFailure(SyncQueueData sale, Object error) async {
    final now = DateTime.now().toUtc();
    await _database.transaction(() async {
      await (_database.update(
        _database.syncQueue,
      )..where((row) => row.idempotencyKey.equals(sale.idempotencyKey))).write(
        SyncQueueCompanion(
          status: const Value('blocked'),
          attempts: Value(sale.attempts + 1),
          lastError: Value(error.toString()),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(_database.orders)
            ..where((row) => row.id.equals(sale.orderId)))
          .write(const OrdersCompanion(syncStatus: Value('sync_conflict')));
    });
  }

  Future<void> _syncAfterConnectivityChange() async {
    try {
      await syncPendingSales();
    } on Object catch (error, stackTrace) {
      log(
        'Background POS sync failed.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  static String _decimalString(Object? value) => value?.toString() ?? '0';

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value.toString()).toUtc();

  static models.Product _productFromCache(Product row) => models.Product(
    id: row.id,
    businessId: row.businessId,
    name: row.name,
    sku: row.sku,
    barcode: row.barcode,
    categoryId: row.categoryId,
    brandId: row.brandId,
    unitId: row.unitId,
    sellingPrice: Decimal.parse(row.sellingPrice),
    taxRate: Decimal.parse(row.taxRate),
    isWeightBased: row.isWeightBased,
    trackBatch: row.trackBatch,
    reorderLevel: Decimal.parse(row.reorderLevel),
    stock: Decimal.parse(row.stock),
    status: row.status,
    imageUrl: row.imageUrl,
    description: row.description,
  );
}
