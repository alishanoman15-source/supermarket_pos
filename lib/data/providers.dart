import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/supabase_provider.dart';
import 'local/held_cart_store.dart';
import 'local/offline_database.dart';
import 'repositories/audit_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/business_repository.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/dashboard_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/import_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/offline_sync_repository.dart';
import 'repositories/parties_repository.dart';
import 'repositories/platform_repository.dart';
import 'repositories/pos_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/promotion_repository.dart';
import 'repositories/purchasing_repository.dart';
import 'repositories/reports_repository.dart';
import 'repositories/shift_repository.dart';
import 'repositories/team_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => BusinessRepository(ref.watch(supabaseClientProvider)),
);

final platformRepositoryProvider = Provider<PlatformRepository>(
  (ref) => PlatformRepository(ref.watch(supabaseClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(supabaseClientProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(supabaseClientProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(supabaseClientProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>(
  (ref) => InventoryRepository(ref.watch(supabaseClientProvider)),
);

final shiftRepositoryProvider = Provider<ShiftRepository>(
  (ref) => ShiftRepository(ref.watch(supabaseClientProvider)),
);

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(ref.watch(supabaseClientProvider)),
);

final partiesRepositoryProvider = Provider<PartiesRepository>(
  (ref) => PartiesRepository(ref.watch(supabaseClientProvider)),
);

final purchasingRepositoryProvider = Provider<PurchasingRepository>(
  (ref) => PurchasingRepository(ref.watch(supabaseClientProvider)),
);

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(supabaseClientProvider)),
);

final promotionRepositoryProvider = Provider<PromotionRepository>(
  (ref) => PromotionRepository(ref.watch(supabaseClientProvider)),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(supabaseClientProvider)),
);

final auditRepositoryProvider = Provider<AuditRepository>(
  (ref) => AuditRepository(ref.watch(supabaseClientProvider)),
);

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(supabaseClientProvider)),
);

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(supabaseClientProvider)),
);

final importRepositoryProvider = Provider<ImportRepository>(
  (ref) => ImportRepository(ref.watch(supabaseClientProvider)),
);

final heldCartStoreProvider = Provider<HeldCartStore>((ref) => const HeldCartStore());

final offlineDatabaseProvider = Provider<OfflineDatabase>((ref) {
  final database = OfflineDatabase();
  ref.onDispose(() => database.close());
  return database;
});

final offlineSyncRepositoryProvider = Provider<OfflineSyncRepository>((ref) {
  final repository = OfflineSyncRepository(
    ref.watch(offlineDatabaseProvider),
    ref.watch(supabaseClientProvider),
  )..start();
  ref.onDispose(() => repository.close());
  return repository;
});
