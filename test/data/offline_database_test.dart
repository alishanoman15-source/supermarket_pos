import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/data/local/offline_database.dart';

void main() {
  late OfflineDatabase database;

  setUp(() {
    database = OfflineDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('catalog products are isolated by branch', () async {
    await database.batch((batch) {
      batch.insert(
        database.products,
        ProductsCompanion.insert(
          id: 'product-1',
          businessId: 'business-1',
          branchId: 'branch-1',
          name: 'Milk',
          sellingPrice: '1.00',
          taxRate: '0',
          isWeightBased: false,
          trackBatch: false,
          reorderLevel: '0',
          stock: '5',
          status: 'active',
          cachedAt: DateTime.utc(2026),
        ),
      );
      batch.insert(
        database.products,
        ProductsCompanion.insert(
          id: 'product-1',
          businessId: 'business-1',
          branchId: 'branch-2',
          name: 'Milk',
          sellingPrice: '1.00',
          taxRate: '0',
          isWeightBased: false,
          trackBatch: false,
          reorderLevel: '0',
          stock: '2',
          status: 'active',
          cachedAt: DateTime.utc(2026),
        ),
      );
    });

    final products = await database.select(database.products).get();
    expect(products, hasLength(2));
    expect(products.map((product) => product.branchId).toSet(), {
      'branch-1',
      'branch-2',
    });
  });

  test('outbox uses idempotency key as a unique transaction key', () async {
    await database
        .into(database.orders)
        .insert(
          OrdersCompanion.insert(
            id: 'local-order-1',
            businessId: 'business-1',
            branchId: 'branch-1',
            shiftId: 'shift-1',
            cashierId: 'cashier-1',
            idempotencyKey: 'sale-key-1',
            subtotal: '10.00',
            discountTotal: '0',
            taxTotal: '0',
            grandTotal: '10.00',
            amountPaid: '10.00',
            changeDue: '0',
            rpcPayload: '{}',
            capturedAt: DateTime.utc(2026),
          ),
        );
    await database
        .into(database.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            idempotencyKey: 'sale-key-1',
            orderId: 'local-order-1',
            businessId: 'business-1',
            cashierId: 'cashier-1',
            payload: '{}',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        );

    final queue = await database.select(database.syncQueue).getSingle();
    expect(queue.status, 'pending');
    expect(queue.orderId, 'local-order-1');
  });
}
