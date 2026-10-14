import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../../settings/providers/settings_providers.dart';

/// My profile (SPEC §9): view and update the signed-in user's own details.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _avatar = TextEditingController();
  bool _busy = false;
  bool _initialised = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _avatar]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(String profileId) async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(profileRepositoryProvider).updateMyProfile(
            profileId: profileId,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            avatarUrl: _avatar.text.trim(),
          );
      await ref.read(sessionControllerProvider.notifier).refresh();
      if (mounted) showSnack(context, l10n.profileUpdated);
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final profile = session.profile;
    final business = ref.watch(businessInfoProvider).valueOrNull;

    if (!_initialised && profile != null) {
      _name.text = profile.name;
      _phone.text = profile.phone ?? '';
      _avatar.text = profile.avatarUrl ?? '';
      _initialised = true;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProfile)),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Identity header — avatar, name and verified address in one
                // place so the account is obvious at a glance.
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          child: Text(
                            profile.name.isEmpty
                                ? '?'
                                : profile.name.characters.first.toUpperCase(),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.name.isEmpty ? '—' : profile.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                session.email ?? '—',
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        if (business?.name != null) ...[
                          const SizedBox(height: 10),
                          Chip(
                            avatar: const Icon(Icons.storefront, size: 18),
                            label: Text(business!.name),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: l10n.account,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _name,
                          label: l10n.fullName,
                          required: true,
                          validator: (v) =>
                              (v?.trim().isEmpty ?? true) ? l10n.required : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _phone,
                          label: l10n.phone,
                          keyboardType: TextInputType.phone,
                          // Optional, but if present it must be a real number.
                          validator: (v) => Validators.phoneOptional(
                            v,
                            invalid: l10n.phoneInvalid,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(controller: _avatar, label: l10n.avatarUrl),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: l10n.business,
                  child: Column(
                    children: [
                      DetailRow(label: l10n.business, value: business?.name ?? '—'),
                      DetailRow(label: l10n.signedInAs, value: session.email ?? '—'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : () => _save(profile.id),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.updateProfile),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
