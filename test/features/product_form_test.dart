import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supermarket_pos/data/models/category.dart' as models;
import 'package:supermarket_pos/data/models/profile.dart';
import 'package:supermarket_pos/data/providers.dart';
import 'package:supermarket_pos/data/repositories/catalog_repository.dart';
import 'package:supermarket_pos/data/repositories/product_repository.dart';
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/products/providers/catalog_providers.dart';
import 'package:supermarket_pos/features/products/screens/product_form_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

SupabaseClient _testClient() => SupabaseClient(
      'http://localhost',
      'test-key',
      // No auto-refresh timer inside widget tests (the test binding fails
      // on pending timers).
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );

/// Records taxonomy creations and hands back fixed ids.
class _FakeCatalogRepo extends CatalogRepository {
  _FakeCatalogRepo() : super(_testClient());

  final created = <String>[];

  @override
  Future<String> createCategory({
    required String businessId,
    required String name,
  }) async {
    created.add('category:$name');
    return 'cat-new';
  }

  @override
  Future<String> createBrand({
    required String businessId,
    required String name,
  }) async {
    created.add('brand:$name');
    return 'brand-new';
  }

  @override
  Future<String> createUnit({
    required String businessId,
    required String name,
  }) async {
    created.add('unit:$name');
    return 'unit-new';
  }
}

/// Records the payload the form tried to save.
class _FakeProductRepo extends ProductRepository {
  _FakeProductRepo() : super(_testClient());

  Map<String, dynamic>? lastValues;

  @override
  Future<void> create({
    required String businessId,
    required Map<String, dynamic> values,
  }) async {
    lastValues = values;
  }
}

class _OnboardedSession extends SessionController {
  @override
  AppSession build() => AppSession(
        AppStatus.ready,
        profile: const Profile(
          id: 'p1',
          authUserId: 'p1',
          businessId: 'b1',
          name: 'Owner',
          status: 'active',
        ),
        email: 'owner@example.com',
      );
}

List<Override> _overrides({
  CatalogRepository? catalog,
  ProductRepository? products,
  List<Override> taxonomy = const [],
}) =>
    [
      // Empty lists by default; a test can pass real rows instead.
      ...(taxonomy.isEmpty
          ? [
              categoriesProvider.overrideWith((ref) async => <models.Category>[]),
              brandsProvider.overrideWith((ref) async => <models.Brand>[]),
              unitsProvider.overrideWith((ref) async => <models.Unit>[]),
            ]
          : taxonomy),
      sessionControllerProvider.overrideWith(() => _OnboardedSession()),
      if (catalog != null) catalogRepositoryProvider.overrideWithValue(catalog),
      if (products != null) productRepositoryProvider.overrideWithValue(products),
    ];

Widget _wrap({List<Override> extra = const [], List<Override> taxonomy = const []}) =>
    ProviderScope(
      overrides: [
        ..._overrides(taxonomy: taxonomy),
        ...extra,
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProductFormScreen(),
      ),
    );

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Save'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('ProductFormScreen', () {
    testWidgets('renders the add-product form', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('Add product'), findsOneWidget);
      expect(find.text('Product name'), findsOneWidget);
      expect(find.text('Selling price'), findsOneWidget);
      // Taxonomy pickers are plain text fields now — users type the name.
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('Unit'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String?>), findsNothing);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('requires the name and selling price', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await _tapSave(tester);

      expect(find.text('This field is required'), findsWidgets);
    });

    testWidgets('rejects a non-numeric selling price', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Cola 1L');
      await tester.enterText(find.byType(TextFormField).at(3), 'abc');
      await _tapSave(tester);

      expect(find.text('Enter a valid number'), findsOneWidget);
    });

    testWidgets('typed category/brand/unit names are created on save',
        (tester) async {
      final catalog = _FakeCatalogRepo();
      final products = _FakeProductRepo();
      final router = GoRouter(
        initialLocation: '/list',
        routes: [
          GoRoute(
              path: '/list',
              builder: (_, _) => const Scaffold(body: Text('LIST'))),
          GoRoute(
              path: '/form',
              builder: (_, _) => const ProductFormScreen()),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(ProviderScope(
        overrides: [
          ..._overrides(catalog: catalog, products: products),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ));
      await tester.pumpAndSettle();
      router.push('/form');
      await tester.pumpAndSettle();

      // Field order: name(0), sku(1), barcode(2), selling(3), purchase(4),
      // tax(5), reorder(6), category(7), brand(8), unit(9).
      await tester.enterText(find.byType(TextFormField).at(0), 'Cola 1L');
      await tester.enterText(find.byType(TextFormField).at(3), '100');
      await tester.enterText(find.byType(TextFormField).at(7), 'Snacks');
      await tester.enterText(find.byType(TextFormField).at(8), 'PepsiCo');
      await tester.enterText(find.byType(TextFormField).at(9), 'Bottle');
      await _tapSave(tester);

      // No rows existed, so all three names create new taxonomy rows...
      expect(catalog.created,
          ['category:Snacks', 'brand:PepsiCo', 'unit:Bottle']);
      // ...and the product payload carries the freshly created ids.
      expect(products.lastValues, isNotNull);
      expect(products.lastValues!['name'], 'Cola 1L');
      expect(products.lastValues!['category_id'], 'cat-new');
      expect(products.lastValues!['brand_id'], 'brand-new');
      expect(products.lastValues!['unit_id'], 'unit-new');

      // The form popped back after the successful save.
      expect(find.text('LIST'), findsOneWidget);
    });

    testWidgets('typing ranks prefix matches first and highlights the hit',
        (tester) async {
      await tester.pumpWidget(_wrap(taxonomy: [
        categoriesProvider.overrideWith((ref) async => [
              const models.Category(
                  id: 'c1', businessId: 'b1', name: 'Snacks', status: 'active'),
              const models.Category(
                  id: 'c2', businessId: 'b1', name: 'Beverages', status: 'active'),
              const models.Category(
                  id: 'c3',
                  businessId: 'b1',
                  name: 'Peanut Snacks',
                  status: 'active'),
            ]),
        brandsProvider.overrideWith((ref) async => <models.Brand>[]),
        unitsProvider.overrideWith((ref) async => <models.Unit>[]),
      ]));
      await tester.pumpAndSettle();

      // Category field is index 7 (see the order note above).
      await tester.enterText(find.byType(TextFormField).at(7), 'sn');
      await tester.pumpAndSettle();

      // Only matching rows are suggested…
      expect(find.text('Beverages'), findsNothing);
      // …with the prefix match (Snacks) ranked above the substring match
      // (Peanut Snacks), and the matched part rendered bold in primary.
      final optionTexts = tester
          .widgetList<Text>(find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Text),
          ))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .toList();
      expect(optionTexts, ['Snacks', 'Peanut Snacks']);
      final snackRow = tester.widget<Text>(find
          .descendant(
            of: find.byType(ListView),
            matching: find.text('Snacks'),
          )
          .first);
      final spans = (snackRow.textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(spans.first.text, 'Sn'); // the highlighted match
      expect(spans.first.style?.fontWeight, FontWeight.w700);

      await tester.tap(find.text('Snacks').first);
      await tester.pumpAndSettle();

      final field = tester.widget<TextFormField>(find.byType(TextFormField).at(7));
      expect(field.controller!.text, 'Snacks');
    });
  });
}
