import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supermarket_pos/core/access/access_policy.dart';
import 'package:supermarket_pos/data/models/profile.dart';
import 'package:supermarket_pos/data/models/team.dart';
import 'package:supermarket_pos/data/providers.dart';
import 'package:supermarket_pos/data/repositories/team_repository.dart';
import 'package:supermarket_pos/features/auth/providers/permissions_controller.dart'
    as auth;
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/team/providers/team_providers.dart';
import 'package:supermarket_pos/features/team/screens/team_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

class _FakeTeamRepo extends TeamRepository {
  _FakeTeamRepo()
      : super(SupabaseClient(
          'http://localhost',
          'test-key',
          // No auto-refresh timer inside widget tests (the test binding
          // fails on pending timers).
          authOptions:
              const FlutterAuthClientOptions(autoRefreshToken: false),
        ));

  final calls = <Map<String, String?>>[];

  @override
  Future<List<AppRole>> fetchRoles() async => const [
        AppRole(id: 'r0', key: 'owner', name: 'Owner'),
        AppRole(id: 'r2', key: 'cashier', name: 'Cashier'),
      ];

  @override
  Future<void> assignRole({
    required String profileId,
    required String roleId,
  }) async {
    calls.add({'profileId': profileId, 'roleId': roleId});
  }

  @override
  Future<void> updateMember({
    required String profileId,
    String? name,
    String? phone,
    String? status,
  }) async {
    calls.add({'profileId': profileId, 'status': status});
  }
}

class _FakeSession extends SessionController {
  _FakeSession(this._profile);
  final Profile _profile;

  @override
  AppSession build() => AppSession(
        AppStatus.ready,
        profile: _profile,
        email: 'owner@example.com',
      );
}

class _FakePermissions extends auth.PermissionsController {
  _FakePermissions(this._policy);
  final AccessPolicy _policy;

  @override
  Future<AccessPolicy> build() async => _policy;
}

const _member = TeamMember(
  id: 'm2',
  name: 'Alice',
  roleId: 'r2',
  roleName: 'Cashier',
  status: 'active',
);

Future<void> _pumpTeam(
  WidgetTester tester, {
  required AccessPolicy policy,
  required _FakeTeamRepo repo,
  TeamMember member = _member,
  bool overrideRoles = true,
}) async {
  final container = ProviderContainer(overrides: [
    sessionControllerProvider.overrideWith(
      () => _FakeSession(const Profile(
        id: 'p1',
        authUserId: 'p1',
        businessId: 'b1',
        roleId: 'r0',
        name: 'Owner',
        status: 'active',
      )),
    ),
    auth.permissionsProvider.overrideWith(() => _FakePermissions(policy)),
    teamRepositoryProvider.overrideWithValue(repo),
    teamProvider.overrideWith((ref) async => [member]),
    if (overrideRoles)
      rolesProvider.overrideWith((ref) async => const <AppRole>[]),
  ]);
  await container.read(auth.permissionsProvider.future);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TeamScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openMenu(WidgetTester tester) async {
  // PopupMenuButton<String> — byType matches the exact instantiated type.
  await tester.tap(find.byType(PopupMenuButton<String>));
  await tester.pumpAndSettle();
}

void main() {
  // Manager template: users.manage but NOT roles.manage.
  const managerPolicy = AccessPolicy({'users.manage'});

  testWidgets('manager sees the team but not the Permissions tab',
      (tester) async {
    await _pumpTeam(tester, policy: managerPolicy, repo: _FakeTeamRepo());

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Permissions'), findsNothing);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('roles.manage holder gets both tabs', (tester) async {
    await _pumpTeam(
      tester,
      policy: const AccessPolicy({'users.manage', 'roles.manage'}),
      repo: _FakeTeamRepo(),
    );

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Employees'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
  });

  testWidgets('deactivating a member asks for confirmation and writes status',
      (tester) async {
    final repo = _FakeTeamRepo();
    await _pumpTeam(tester, policy: managerPolicy, repo: repo);

    await _openMenu(tester);
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();

    // Confirmation with a clear consequence first.
    expect(find.text('They will no longer be able to sign in to the app. '
            'You can reactivate them later.'),
        findsOneWidget);
    expect(repo.calls, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Deactivate'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single['profileId'], 'm2');
    expect(repo.calls.single['status'], 'inactive');
  });

  testWidgets('an inactive member is reactivated without a dialog',
      (tester) async {
    final repo = _FakeTeamRepo();
    await _pumpTeam(
      tester,
      policy: managerPolicy,
      repo: repo,
      member: const TeamMember(
        id: 'm2',
        name: 'Alice',
        roleId: 'r2',
        roleName: 'Cashier',
        status: 'inactive',
      ),
    );

    await _openMenu(tester);
    await tester.tap(find.text('Activate'));
    await tester.pumpAndSettle();

    // No confirmation dialog for reactivation.
    expect(find.text('Activate'), findsNothing);
    expect(repo.calls.single['status'], 'active');
  });

  testWidgets('cannot deactivate your own account', (tester) async {    final repo = _FakeTeamRepo();
    // Member id == signed-in profile id (p1).
    await _pumpTeam(
      tester,
      policy: managerPolicy,
      repo: repo,
      member: const TeamMember(
        id: 'p1',
        name: 'Owner',
        roleId: 'r0',
        roleName: 'Owner',
        status: 'active',
      ),
    );

    await _openMenu(tester);
    await tester.tap(find.text('Deactivate'));
    await tester.pumpAndSettle();

    expect(find.text('You cannot deactivate your own account.'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('assign-role picker loads roles on demand (lazy provider)',
      (tester) async {
    // Regression: the dialog used to READ the roles provider cold, so the
    // dropdown opened with zero items and no role could ever be picked.
    final repo = _FakeTeamRepo();
    await _pumpTeam(
      tester,
      policy: managerPolicy,
      repo: repo,
      overrideRoles: false, // roles come from repo.fetchRoles() on demand
    );

    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Dialog awaits the catalogue, so the current role is already selected.
    expect(find.text('Assign role'), findsOneWidget);
    expect(find.text('Cashier'), findsWidgets); // subtitle + selected value

    // Open the dropdown and switch to Owner.
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Owner'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(repo.calls, hasLength(1));
    expect(repo.calls.single['profileId'], 'm2');
    expect(repo.calls.single['roleId'], 'r0');
  });
}
