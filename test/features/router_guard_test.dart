import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supermarket_pos/core/access/access_policy.dart';
import 'package:supermarket_pos/core/router/app_router.dart';
import 'package:supermarket_pos/data/models/product.dart';
import 'package:supermarket_pos/data/models/profile.dart';
import 'package:supermarket_pos/features/auth/providers/permissions_controller.dart';
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/pos/providers/pos_providers.dart';
import 'package:supermarket_pos/features/pos/screens/pos_screen.dart';
import 'package:supermarket_pos/features/shifts/providers/shift_providers.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

/// The cashier template from create_business_with_owner (SPEC §3.4).
const _cashierKeys = {
  'pos.sell',
  'pos.hold',
  'products.view',
  'inventory.view',
  'sales.view',
  'customers.manage',
  'shifts.open',
  'shifts.close',
  'cash.move',
  'reports.shift.self',
  'notifications.view',
};

class _FakeSession extends SessionController {
  _FakeSession(this._value);
  final AppSession _value;

  @override
  AppSession build() => _value;
}

class _FakePermissions extends PermissionsController {
  _FakePermissions(this._policy);
  final AccessPolicy _policy;

  @override
  Future<AccessPolicy> build() async => _policy;
}

AppSession _sessionFor(AppStatus status) => AppSession(
      status,
      profile: status == AppStatus.signedOut
          ? null
          : const Profile(
              id: 'p1',
              authUserId: 'u1',
              businessId: 'b1',
              branchId: 'br1',
              roleId: 'r1',
              name: 'Test User',
              status: 'active',
            ),
      email: 'user@example.com',
    );

/// Builds the real [appRouterProvider] with a faked session/policy and the
/// data providers the POS landing screen touches stubbed out, then resolves
/// the policy so the guard never sees the loading fail-open state.
Future<(ProviderContainer, GoRouter)> _router({
  required AppSession session,
  AccessPolicy policy = const AccessPolicy(_cashierKeys),
}) async {
  final container = ProviderContainer(overrides: [
    sessionControllerProvider.overrideWith(() => _FakeSession(session)),
    permissionsProvider.overrideWith(() => _FakePermissions(policy)),
    myOpenShiftProvider.overrideWith((ref) async => null),
    currentBusinessProvider.overrideWith((ref) async => null),
    posProductsProvider.overrideWith((ref, String query) async => <Product>[]),
  ]);
  await container.read(permissionsProvider.future);
  final router = container.read(appRouterProvider);
  addTearDown(container.dispose);
  return (container, router);
}

Future<void> _pump(WidgetTester tester, ProviderContainer c, GoRouter router) {
  return tester.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  testWidgets('cashier deep-linking to a denied module lands on the POS',
      (tester) async {
    final (container, router) = await _router(session: _sessionFor(AppStatus.ready));

    for (final denied in [
      // Note: the reports *hub* is reachable for a cashier (their own cash
      // report matches reports.*); the individual financial reports are not.
      '/app/reports/profit',
      '/app/reports/sales',
      '/app/team',
      '/app/dashboard',
      '/app/suppliers',
    ]) {
      router.go(denied);
      await _pump(tester, container, router);
      await tester.pumpAndSettle();

      expect(router.routerDelegate.currentConfiguration.uri.path, '/app/pos',
          reason: '$denied must redirect a cashier to their home (POS)');
      expect(find.byType(PosScreen), findsOneWidget);
    }
  });

  testWidgets('unauthenticated deep link goes to /login', (tester) async {
    final (container, router) =
        await _router(session: _sessionFor(AppStatus.signedOut));

    router.go('/app/dashboard');
    await _pump(tester, container, router);
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
  });

  testWidgets('deactivated account is held on /login with a clear notice',
      (tester) async {
    final (container, router) =
        await _router(session: _sessionFor(AppStatus.deactivated));

    router.go('/app/pos');
    await _pump(tester, container, router);
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.path, '/login');
    // The localized "account deactivated" notice is on screen (English in
    // the default test locale).
    expect(
        find.text(
            'This account has been deactivated. Contact your business administrator to reactivate it.'),
        findsOneWidget);
  });
}
