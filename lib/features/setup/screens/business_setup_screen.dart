import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';

/// First-run onboarding. Calls the atomic `create_business_with_owner` RPC —
/// never multi-step client writes (SPEC §65, BACKEND_SETUP rule #3).
class BusinessSetupScreen extends ConsumerStatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  ConsumerState<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends ConsumerState<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _branchName = TextEditingController(text: 'Main Branch');
  final _phone = TextEditingController();
  final _address = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _businessName.dispose();
    _branchName.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(businessRepositoryProvider).createBusinessWithOwner(
            business: {
              'name': _businessName.text.trim(),
              'phone': _phone.text.trim(),
              'address': _address.text.trim(),
              'currency': 'PKR',
              'timezone': 'Asia/Karachi',
            },
            branch: {
              'name': _branchName.text.trim(),
              'phone': _phone.text.trim(),
              'address': _address.text.trim(),
            },
          );
      // Re-resolve session → router redirects to the dashboard.
      await ref.read(sessionControllerProvider.notifier).refresh();
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.businessSetupTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Intro header — mirrors the login/signup card style so the
                  // whole first-run flow feels like one product.
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.storefront_rounded, size: 32, color: scheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.businessSetupTitle,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.businessSetupSubtitle, style: text.bodyMedium),
                  const SizedBox(height: 24),

                  // Form card
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _businessName,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.organizationName],
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.businessName,
                                prefixIcon: const Icon(Icons.store),
                              ),
                              validator: (v) => Validators.requiredText(v, message: l10n.nameRequired),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _branchName,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.branchName,
                                prefixIcon: const Icon(Icons.storefront),
                              ),
                              validator: (v) => Validators.requiredText(v, message: l10n.nameRequired),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              autofillHints: const [AutofillHints.telephoneNumber],
                              textInputAction: TextInputAction.next,
                              inputFormatters: [
                                // Only phone characters, and a sane cap: E.164
                                // tops out at 15 digits, so a 17-digit typo can
                                // never be typed or pasted in full.
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+\-\s()]'),
                                ),
                                LengthLimitingTextInputFormatter(18),
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                              ),
                              // Business contact must be a real, reachable number
                              // (7–15 digits, E.164) — rejects 17-digit typos.
                              validator: (v) => Validators.phone(
                                v,
                                required: l10n.phoneRequired,
                                invalid: l10n.phoneInvalid,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _address,
                              maxLines: 2,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l10n.address,
                                prefixIcon: const Icon(Icons.location_on_outlined),
                              ),
                              // The shop address appears on receipts and
                              // reports, so it is required up front.
                              validator: (v) => Validators.requiredText(v, message: l10n.required),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                              child: _busy
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(l10n.saveAndContinue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
