import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/dashboard_kpis.dart';
import '../../../data/providers.dart';

/// Dashboard KPIs come from the server-side aggregation RPC (SPEC §31, §49),
/// never from raw row downloads.
final dashboardKpisProvider = FutureProvider.autoDispose<DashboardKpis>((ref) {
  return ref.watch(dashboardRepositoryProvider).fetchKpis();
});
