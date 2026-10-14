import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/profile.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';

enum AppStatus { loading, signedOut, needsBusiness, ready, deactivated }

class AppSession {
  final AppStatus status;
  final Profile? profile;
  final String? email;

  /// True when the signed-in user is a platform super admin (SPEC §3.1):
  /// full cross-business access, no business onboarding required.
  final bool isSuperAdmin;

  const AppSession(
    this.status, {
    this.profile,
    this.email,
    this.isSuperAdmin = false,
  });

  bool get isReady => status == AppStatus.ready;
}

/// Resolves the app-level session: signed out, missing onboarding, or ready.
/// Watched by the router so guards react to sign-in / sign-out instantly.
class SessionController extends Notifier<AppSession> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  AppSession build() {
    final sub = _auth.authStateChanges.listen((_) => _resolve());
    ref.onDispose(sub.cancel);
    _resolve();
    return const AppSession(AppStatus.loading);
  }

  Future<void> _resolve() async {
    final session = _auth.currentSession;
    if (session == null) {
      state = const AppSession(AppStatus.signedOut);
      return;
    }
    final email = _auth.currentUser?.email;
    try {
      final profile = await ref.read(profileRepositoryProvider).fetchMyProfile();
      // A deactivated account (profiles.status != 'active') must never reach
      // onboarding or the app: RLS already blocks every permission-gated
      // call; the UI just needs a clear reason instead of a silent sign-out.
      // The profiles RLS policy lets a user read their own row regardless of
      // status, so the status is visible here even for disabled accounts.
      if (profile != null && !profile.isActive) {
        state = AppSession(
          AppStatus.deactivated,
          profile: profile,
          email: email,
        );
        return;
      }
      // A platform super admin (SPEC §3.1) never goes through onboarding —
      // they administer every business, including ones they do not own.
      final isSuperAdmin =
          await ref.read(platformRepositoryProvider).isSuperAdmin();
      if (isSuperAdmin && (profile == null || !profile.hasBusiness)) {
        state = AppSession(
          AppStatus.ready,
          profile: profile,
          email: email,
          isSuperAdmin: true,
        );
      } else if (profile == null || !profile.hasBusiness) {
        state = AppSession(AppStatus.needsBusiness, profile: profile, email: email);
      } else {
        state = AppSession(
          AppStatus.ready,
          profile: profile,
          email: email,
          isSuperAdmin: isSuperAdmin,
        );
      }
    } catch (_) {
      state = const AppSession(AppStatus.signedOut);
    }
  }

  /// Re-resolve after onboarding or a profile change.
  Future<void> refresh() => _resolve();
}

final sessionControllerProvider =
    NotifierProvider<SessionController, AppSession>(SessionController.new);
