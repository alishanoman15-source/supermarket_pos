import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/offline_database.dart';
import '../../../data/providers.dart';

/// Live view of the offline-sale sync queue (SPEC §62): one row per locally
/// stored sale with `pending` / `synced` / `blocked` state, retry count and the
/// last server error.
final syncQueueProvider = StreamProvider<List<SyncQueueData>>((ref) {
  return ref.watch(offlineSyncRepositoryProvider).watchQueue();
});
