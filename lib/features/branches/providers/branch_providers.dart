import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/branch.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';

/// Branches of the signed-in business (SPEC §6).
final branchesProvider = FutureProvider<List<Branch>>((ref) async {
  final businessId = ref.watch(sessionControllerProvider).profile?.businessId;
  if (businessId == null) return const [];
  return ref.watch(businessRepositoryProvider).fetchBranches(businessId);
});

/// POS terminals/counters of the signed-in business (SPEC §77, screen #59).
final terminalsProvider = FutureProvider<List<PosTerminal>>((ref) {
  return ref.watch(businessRepositoryProvider).fetchTerminals();
});
