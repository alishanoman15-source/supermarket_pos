import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';
import '../providers/session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Address to prefill — the sign-up screen hands over the email that
  /// already has an account so the person only has to type the password.
  final String? initialEmail;

  const LoginScreen({super.key, this.initialEmail});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  /// 0 = password, 1 = email OTP (SPEC §4). Password is the default; the
  /// switch keeps both entry points on one screen. Note: the OTP email uses
  /// Supabase's built-in template until custom SMTP is configured
  /// (BACKEND_SETUP.md §16) — the code still arrives, only the wording is
  /// Supabase's default.
  int _mode = 0;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail;
    if (email != null && email.isNotEmpty) _email.text = email;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPassword(
            email: _email.text,
            password: _password.text,
          );
      // Success: SessionController updates and the router redirects.
    } on AppException catch (e) {
      if (mounted) {
        // Wrong email/password gets a translated, actionable message — an
        // invited member is told they can keep the password chosen while
        // accepting the invite, or ask the owner to reset it from Team
        // (SPEC §23).
        final l10n = context.l10n;
        final text = e.isInvalidCredentials
            ? '${l10n.invalidLogin} ${l10n.accountExistsHelp}'
            : e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(text), duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Email OTP path: mail the code, then hand over to the `/otp` screen
  /// which owns verification + resend (SPEC §4).
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailOtp(email: _email.text);
      if (mounted) context.push(AppRoutes.otp, extra: _email.text.trim());
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), duration: const Duration(seconds: 8)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    // A deactivated profile (RLS already blocks it server-side) gets a clear
    // explanation here instead of a silent failed sign-in.
    final deactivated =
        ref.watch(sessionControllerProvider).status == AppStatus.deactivated;

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
                      child: Icon(Icons.storefront_rounded, size: 44, color: scheme.primary),
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
                      l10n.signInSubtitle,
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
                              Text(
                                l10n.welcomeBack,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              if (deactivated) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: scheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.block_outlined,
                                          color: scheme.onErrorContainer),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l10n.accountDeactivated,
                                          style: TextStyle(
                                              color: scheme.onErrorContainer),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              SegmentedButton<int>(
                                segments: [
                                  ButtonSegment(
                                    value: 0,
                                    label: Text(l10n.password),
                                    icon: const Icon(Icons.lock_outline, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: 1,
                                    label: Text(l10n.otpCode),
                                    icon: const Icon(Icons.mail_outline, size: 18),
                                  ),
                                ],
                                selected: {_mode},
                                showSelectedIcon: false,
                                onSelectionChanged: _busy
                                    ? null
                                    : (selection) =>
                                        setState(() => _mode = selection.first),
                              ),
                              const SizedBox(height: 20),
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
                              if (_mode == 0) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _busy
                                        ? null
                                        : () => context.push(AppRoutes.forgotPassword),
                                    child: Text(l10n.forgotPassword),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                FilledButton(
                                  onPressed: _busy ? null : _submit,
                                  child: _busy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(l10n.signIn),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: _busy ? null : _sendOtp,
                                  icon: const Icon(Icons.mail_lock_outlined),
                                  label: _busy
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(l10n.sendOtp),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _busy ? null : () => context.push(AppRoutes.register),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onPrimary,
                      ),
                      child: Text(l10n.noAccount),
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
