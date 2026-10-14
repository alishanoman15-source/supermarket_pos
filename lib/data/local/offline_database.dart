import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'offline_database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get name => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// POS-safe catalogue projection. Prices and quantities stay decimal strings;
/// purchase costs are deliberately excluded from the offline POS cache.
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get brandId => text().nullable()();
  TextColumn get unitId => text().nullable()();
  TextColumn get sellingPrice => text()();
  TextColumn get taxRate => text()();
  BoolColumn get isWeightBased => boolean()();
  BoolColumn get trackBatch => boolean()();
  TextColumn get reorderLevel => text()();
  TextColumn get stock => text()();
  TextColumn get status => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id, branchId};
}

/// Local order header mirrors Supabase `sales`; `id` is created on-device,
/// while `serverSaleId` is populated only after the RPC confirms the sale.
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  TextColumn get shiftId => text()();
  TextColumn get cashierId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get invoiceNumber => text().nullable()();
  TextColumn get subtotal => text()();
  TextColumn get discountTotal => text()();
  TextColumn get taxTotal => text()();
  TextColumn get grandTotal => text()();
  TextColumn get amountPaid => text()();
  TextColumn get changeDue => text()();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending_sync'))();
  TextColumn get note => text().nullable()();
  TextColumn get rpcPayload => text()();
  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get serverSoldAt => dateTime().nullable()();
  DateTimeColumn get serverCreatedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get serverSaleId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Immutable line snapshot mirrors Supabase `sale_items`.
class OrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get productId => text()();
  TextColumn get batchId => text().nullable()();
  TextColumn get serverItemId => text().nullable()();
  TextColumn get nameSnapshot => text()();
  TextColumn get skuSnapshot => text().nullable()();
  TextColumn get barcodeSnapshot => text().nullable()();
  TextColumn get qty => text()();
  TextColumn get unitPrice => text()();
  TextColumn get costAtSale => text().nullable()();
  TextColumn get discount => text().withDefault(const Constant('0'))();
  TextColumn get taxRate => text().withDefault(const Constant('0'))();
  TextColumn get taxAmount => text().nullable()();
  TextColumn get lineTotal => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Durable transactional outbox. The RPC payload (including its idempotency
/// key) is stored before any network request is attempted.
class SyncQueue extends Table {
  TextColumn get idempotencyKey => text()();
  TextColumn get orderId => text().references(Orders, #id)();
  TextColumn get businessId => text()();
  TextColumn get cashierId => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {idempotencyKey};
}

class CatalogCacheStates extends Table {
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {businessId, branchId};
}

class PosShifts extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get businessId => text()();
  TextColumn get branchId => text()();
  TextColumn get status => text()();
  TextColumn get openingFloat => text()();
  TextColumn get closingCounted => text().nullable()();
  TextColumn get expectedCash => text().nullable()();
  TextColumn get variance => text().nullable()();
  TextColumn get varianceReason => text().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Categories,
    Products,
    Orders,
    OrderItems,
    SyncQueue,
    CatalogCacheStates,
    PosShifts,
  ],
)
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'supermarket_pos',
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(catalogCacheStates);
      }
      if (from < 3) {
        await migrator.renameColumn(orders, 'status', orders.syncStatus);
        await migrator.addColumn(orders, orders.status);
        await migrator.addColumn(categories, categories.createdAt);
        await migrator.addColumn(orders, orders.createdAt);
        await migrator.addColumn(orders, orders.serverSoldAt);
        await migrator.addColumn(orders, orders.serverCreatedAt);
        await migrator.addColumn(products, products.createdAt);
        await migrator.addColumn(products, products.deletedAt);
        await migrator.addColumn(orderItems, orderItems.batchId);
        await migrator.addColumn(orderItems, orderItems.serverItemId);
        await migrator.addColumn(orderItems, orderItems.createdAt);
      }
      if (from < 4) {
        await migrator.createTable(posShifts);
      }
    },
  );
}
