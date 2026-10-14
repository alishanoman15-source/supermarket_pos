import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_pos/features/auth/providers/session_controller.dart';
import 'package:supermarket_pos/features/auth/screens/login_screen.dart';
import 'package:supermarket_pos/l10n/generated/app_localizations.dart';

class _SignedOutSession extends SessionController {
  @override
  AppSession build() => const AppSession(AppStatus.signedOut);
}

Widget _wrap() => ProviderScope(
      overrides: [
        sessionControllerProvider.overrideWith(() => _SignedOutSession()),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginScreen(),
      ),
    );

void main() {
  group('LoginScreen', () {
    testWidgets('renders localized email, password and sign-in labels', (tester) async {
      await tester.pumpWidget(_wrap());

      expect(find.text('Welcome back'), findsOneWidget);
      // Password mode (default): email + password fields, sign-in button.
      // The 'Password' / 'OTP code' labels are the mode-switch segments.
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsWidgets);
      expect(find.text('OTP code'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text("Don't have an account? Create one"), findsOneWidget);
    });

    testWidgets('shows localized validation messages when fields are empty', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('OTP mode swaps the password field for Send OTP', (tester) async {
      await tester.pumpWidget(_wrap());

      // Switch to the OTP segment.
      await tester.tap(find.text('OTP code'));
      await tester.pumpAndSettle();

      // Password field is gone; the OTP action replaces Sign in.
      expect(find.text('Enter your password'), findsNothing);
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Send OTP'), findsOneWidget);
      // Email stays in both modes.
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('OTP mode validates the email before sending', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('OTP code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send OTP'));
      await tester.pump();

      expect(find.text('Enter your email address'), findsOneWidget);
      // No navigation to the verification screen on an invalid form.
      expect(find.text('Verify'), findsNothing);
    });

    testWidgets('switching back to password restores the password field', (tester) async {
      await tester.pumpWidget(_wrap());

      await tester.tap(find.text('OTP code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Password'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Send OTP'), findsNothing);
    });
  });
}
