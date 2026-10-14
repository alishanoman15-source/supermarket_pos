import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/business.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';

/// Business row for the signed-in user's business (RLS-scoped).
final businessInfoProvider = FutureProvider.autoDispose<Business?>((ref) {
  final profile = ref.watch(sessionControllerProvider).profile;
  final id = profile?.businessId;
  if (id == null) return Future.value(null);
  return ref.watch(businessRepositoryProvider).fetchById(id);
});
