import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import 'package:supermarket_pos/core/errors/app_exception.dart';
import 'package:supermarket_pos/data/providers.dart';
import 'package:supermarket_pos/data/repositories/auth_repository.dart';
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/auth/screens/login_screen.dart';
import 'package:supermarket_pos/features/auth/screens/register_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

class _SignedOutSession extends SessionController {
  @override
  AppSession build() => const AppSession(AppStatus.signedOut);
}

/// Auth repo that always rejects the credentials (Supabase's
/// `Invalid login credentials`).
class _BadPasswordAuth extends AuthRepository {
  _BadPasswordAuth() : super(_client);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw AppException.from(const AuthException('Invalid login credentials'));
  }
}

/// Shared client for the fake repo; its auto-refresh timer is stopped in the
/// test body so no timer outlives the widget tree.
final SupabaseClient _client = SupabaseClient('http://localhost', 'anon');

/// Auth repo that behaves exactly like Supabase does for an address that
/// already belongs to an account (typically staff who were invited and are
/// trying to sign up instead of signing in).
class _ExistingAccountAuth extends AuthRepository {
  _ExistingAccountAuth() : super(_client);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    throw AppException.from(const AuthException('User already registered'));
  }
}

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/register',
    routes: [
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(initialEmail: state.extra as String?),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      sessionControllerProvider.overrideWith(() => _SignedOutSession()),
      authRepositoryProvider.overrideWithValue(_ExistingAccountAuth()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets(
      'sign-up of an already-registered (invited) email explains itself and '
      'lands on sign-in with the address filled in', (tester) async {
    // GoTrue starts a periodic auto-refresh timer on construction; stop it so
    // no timer outlives the widget tree.
    _client.auth.stopAutoRefresh();
    await tester.pumpWidget(_wrap());

    await tester.enterText(find.byType(TextFormField).at(0), 'ali');
    await tester.enterText(find.byType(TextFormField).at(1), 'alishanomann@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'Secret123');
    await tester.enterText(find.byType(TextFormField).at(3), 'Secret123');

    // The submit button sits below the fold on the default test surface.
    await tester.ensureVisible(find.text('Sign up'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    // The guidance is shown instead of a bare backend error.
    expect(
      find.textContaining('This email already has an account.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ask the owner to reset it from Team'),
      findsOneWidget,
    );

    // ...and the person is now on the sign-in screen with the email ready.
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('alishanomann@gmail.com'), findsOneWidget);

    // Let the guidance snackbar expire so its timer does not outlive the tree.
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a wrong password explains itself and points at the owner reset',
      (tester) async {
    // See the note in the sign-up test: no timer may outlive the tree.
    _client.auth.stopAutoRefresh();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionControllerProvider.overrideWith(() => _SignedOutSession()),
          authRepositoryProvider.overrideWithValue(_BadPasswordAuth()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'alishanomann@gmail.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    // Translated guidance instead of the raw backend string.
    expect(
      find.textContaining('Incorrect email or password'),
      findsOneWidget,
    );
    expect(
      find.textContaining('ask the owner to reset it from Team'),
      findsOneWidget,
    );
    // No navigation happens on a failed sign-in.
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();
  });
}
