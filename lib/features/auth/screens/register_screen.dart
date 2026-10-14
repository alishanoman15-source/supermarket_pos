import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';

/// Sign-up (SPEC §4). Mirrors the sign-in screen: gradient brand header,
/// card-contained form, confirm-password step so a typo'd password never
/// locks a brand-new account out.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signUp(
        email: _email.text.trim(),
        password: _password.text,
        fullName: _name.text.trim(),
      );
      if (!mounted) return;
      if (repo.currentSession == null) {
        // Safety net only: auto-confirm is on, so sign-up normally returns a
        // session straight away. Without one, send the person to sign in
        // rather than the OTP screen — the code email cannot be delivered
        // until a custom SMTP provider is configured (BACKEND_SETUP.md §16).
        showSnack(context, l10n.confirmEmailSent);
        context.go(AppRoutes.login, extra: _email.text.trim());
        return;
      }
      // Otherwise SessionController resolves → router sends to onboarding.
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.isEmailAlreadyRegistered) {
        // The mailbox already belongs to an account — usually staff who were
        // invited and are trying to sign up instead of signing in. Explain
        // instead of failing silently, then drop them on the sign-in screen
        // with the address filled in.
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('${l10n.accountExists} ${l10n.accountExistsHelp}'),
            duration: const Duration(seconds: 7),
          ),
        );
        context.go(AppRoutes.login, extra: _email.text.trim());
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primary, scheme.primaryContainer],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand header
                    Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.onPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded, size: 44, color: scheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.signUpSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onPrimary.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 28),

                    // Form card
                    Card(
                      elevation: 3,
                      color: scheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Same in-card heading rhythm as the sign-in
                              // card, so both screens read as one flow.
                              Text(
                                l10n.createAccount,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.name],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: l10n.fullName,
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    Validators.requiredText(v, message: l10n.nameRequired),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: l10n.email,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                ),
                                validator: (v) => Validators.email(
                                  v,
                                  required: l10n.emailRequired,
                                  invalid: l10n.emailInvalid,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.newPassword],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: l10n.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscure ? 'Show password' : 'Hide password',
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => Validators.password(
                                  v,
                                  required: l10n.passwordRequired,
                                  tooShort: l10n.passwordTooShort,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirm,
                                obscureText: _obscure,
                                autofillHints: const [AutofillHints.newPassword],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: l10n.confirmPassword,
                                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                                ),
                                // Re-type guard: the account is created with
                                // exactly this password, so catch typos here.
                                validator: (v) {
                                  if ((v ?? '').isEmpty) return l10n.passwordRequired;
                                  if (v != _password.text) return l10n.passwordsDoNotMatch;
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _busy ? null : _submit,
                                child: _busy
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(l10n.signUp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Google sign-up removed: sign-up is email-only and the
                    // address is verified with a one-time code (SPEC §4).
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => context.go(AppRoutes.login),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onPrimary,
                      ),
                      child: Text(l10n.alreadyHaveAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
