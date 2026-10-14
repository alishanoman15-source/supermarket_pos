import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/core/access/access_policy.dart';
import 'package:supermarket_pos/core/ui/permission_gate.dart';
import 'package:supermarket_pos/features/auth/providers/permissions_controller.dart';

class _FakePermissions extends PermissionsController {
  _FakePermissions(this._policy);
  final AccessPolicy _policy;

  @override
  Future<AccessPolicy> build() async => _policy;
}

Widget _app(AccessPolicy policy, Widget gate) => ProviderScope(
      overrides: [permissionsProvider.overrideWith(() => _FakePermissions(policy))],
      child: MaterialApp(home: Scaffold(body: gate)),
    );

void main() {
  const sensitive = Text('Cost: 100');

  testWidgets('shows the child when the role holds the permission',
      (tester) async {
    await tester.pumpWidget(_app(
      const AccessPolicy({'products.view_cost'}),
      const PermissionGate(permission: 'products.view_cost', child: sensitive),
    ));
    // Let the async permission policy resolve (the first frame is the
    // loading fail-open).
    await tester.pumpAndSettle();

    expect(find.text('Cost: 100'), findsOneWidget);
  });

  testWidgets('hides the child when the permission is missing', (tester) async {
    await tester.pumpWidget(_app(
      const AccessPolicy({'products.view'}),
      const PermissionGate(permission: 'products.view_cost', child: sensitive),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cost: 100'), findsNothing);
  });

  testWidgets('renders the fallback instead of nothing when provided',
      (tester) async {
    await tester.pumpWidget(_app(
      const AccessPolicy({'products.view'}),
      const PermissionGate(
        permission: 'products.view_cost',
        fallback: Text('Hidden'),
        child: sensitive,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cost: 100'), findsNothing);
    expect(find.text('Hidden'), findsOneWidget);
  });

  testWidgets('allow-all policy (the loading fail-open) shows the child',
      (tester) async {
    await tester.pumpWidget(_app(
      const AccessPolicy.allowAll(),
      const PermissionGate(permission: 'products.view_cost', child: sensitive),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Cost: 100'), findsOneWidget);
  });
}
