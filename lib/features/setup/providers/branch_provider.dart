import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/branch.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';

/// Branches of the signed-in user's business (RLS-scoped). Used by the
/// transfer editor and any branch picker.
final branchesProvider = FutureProvider.autoDispose<List<Branch>>((ref) {
  final businessId = ref.watch(sessionControllerProvider).profile?.businessId;
  if (businessId == null) return Future.value(const []);
  return ref.watch(businessRepositoryProvider).fetchBranches(businessId);
});
