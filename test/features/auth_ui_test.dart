import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/auth/screens/login_screen.dart';
import 'package:supermarket_pos/features/auth/screens/register_screen.dart';
import 'package:supermarket_pos/features/setup/screens/business_setup_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

class _SignedOutSession extends SessionController {
  @override
  AppSession build() => const AppSession(AppStatus.signedOut);
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _SignedOutSession()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  group('Google sign-in removal', () {
    testWidgets('login no longer offers Continue with Google', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));

      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    });

    testWidgets('signup no longer offers Continue with Google', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsNothing);
    });
  });

  group('RegisterScreen', () {
    testWidgets('mirrors the sign-in layout: brand header + card fields', (tester) async {
      await tester.pumpWidget(_wrap(const RegisterScreen()));

      // Same brand header as login, then the in-card title.
      expect(find.text('Supermarket POS'), findsOneWidget);
      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });
  });

  group('BusinessSetupScreen validation', () {
    testWidgets('rejects an over-long phone number and a missing address',
        (tester) async {
      await tester.pumpWidget(_wrap(const BusinessSetupScreen()));
      await tester.pumpAndSettle();

      // Fill names so only phone/address fail.
      await tester.enterText(find.byType(TextFormField).at(0), 'Super Store');
      await tester.enterText(find.byType(TextFormField).at(1), 'Small Shop');
      // The exact typo from the field report: 17 digits.
      await tester.enterText(find.byType(TextFormField).at(2), '03301783237219873');

      // Validate through the Form itself so no backend call is attempted.
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isFalse);
      await tester.pump();

      expect(find.text('Enter a valid phone number'), findsOneWidget);
      expect(find.text('This field is required'), findsOneWidget);
    });

    testWidgets('accepts a real PK mobile number once the address is filled',
        (tester) async {
      await tester.pumpWidget(_wrap(const BusinessSetupScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Super Store');
      await tester.enterText(find.byType(TextFormField).at(1), 'Small Shop');
      await tester.enterText(find.byType(TextFormField).at(2), '0300 1234567');
      await tester.enterText(find.byType(TextFormField).at(3), 'Main Bazaar');

      // Valid input → the form validates clean. The RPC call itself is not
      // exercised here (no backend in widget tests).
      final form = tester.state<FormState>(find.byType(Form));
      expect(form.validate(), isTrue);
      await tester.pump();

      expect(find.text('Enter a valid phone number'), findsNothing);
      expect(find.text('This field is required'), findsNothing);
    });
  });
}
