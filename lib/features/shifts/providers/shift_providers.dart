import 'dart:async';

import 'package:http/http.dart' show ClientException;
import '../../../core/platform/io_compat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/shift.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';

/// The signed-in user's shifts, newest first (RLS scopes visibility).
final shiftsProvider = FutureProvider.autoDispose<List<Shift>>(
  (ref) => ref.watch(shiftRepositoryProvider).fetchShifts(),
);

/// The caller's currently open shift, or null.
final myOpenShiftProvider = FutureProvider.autoDispose<Shift?>((ref) async {
  final profile = ref.watch(sessionControllerProvider).profile;
  if (profile == null) return null;
  final profileId = profile.id;
  try {
    final shifts = await ref.watch(shiftRepositoryProvider).fetchShifts();
    if (profile.businessId != null) {
      await ref
          .read(offlineSyncRepositoryProvider)
          .cacheShifts(profileId, profile.businessId!, shifts);
    }
    for (final shift in shifts) {
      if (shift.isOpen) return shift; // RLS already restricts visible shifts
    }
    return null;
  } on AppException catch (error) {
    if (!_isNetworkFailure(error)) rethrow;
    return ref.read(offlineSyncRepositoryProvider).cachedOpenShift(profileId);
  }
});

final cashMovementsProvider = FutureProvider.autoDispose
    .family<List<CashMovement>, String>(
      (ref, shiftId) =>
          ref.watch(shiftRepositoryProvider).fetchCashMovements(shiftId),
    );

bool _isNetworkFailure(AppException error) =>
    error.cause is IOException ||
    error.cause is ClientException ||
    error.cause is TimeoutException;
