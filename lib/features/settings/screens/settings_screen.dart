import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_locale.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/business.dart';
import '../../../data/models/team.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../../team/providers/team_providers.dart';
import '../providers/settings_providers.dart';

/// Settings (SPEC §33): account, business, preferences and sign-out.
/// Grouped cards instead of one flat list so every section is scannable.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: context.l10n.logout,
      message: context.l10n.logoutConfirm,
      confirmLabel: context.l10n.logout,
      destructive: true,
    );
    if (!ok) return;
    try {
      await ref.read(authRepositoryProvider).signOut();
      // SessionController reacts and the router returns to /login.
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(appLanguageProvider);
    final selected = await showDialog<AppLanguage>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          RadioGroup<AppLanguage>(
            groupValue: current,
            onChanged: (v) {
              if (v == null) return;
              Navigator.pop(context, v);
            },
            child: Column(
              children: [
                for (final language in AppLanguage.values)
                  RadioListTile<AppLanguage>(
                    value: language,
                    title: Text(switch (language) {
                      AppLanguage.system => l10n.languageSystem,
                      AppLanguage.english => l10n.languageEnglish,
                      AppLanguage.urdu => l10n.languageUrdu,
                    }),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    await ref.read(appLanguageProvider.notifier).set(selected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final session = ref.watch(sessionControllerProvider);
    final business = ref.watch(businessInfoProvider);
    final profile = session.profile;
    final language = ref.watch(appLanguageProvider);

    // Role name for the signed-in profile (empty while it loads).
    final roles = ref.watch(rolesProvider).valueOrNull ?? const <AppRole>[];
    final roleName = roles
        .where((r) => r.id == profile?.roleId)
        .map((r) => r.name)
        .followedBy(const ['—'])
        .first;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------------------------------------------------- Account
          SectionCard(
            title: l10n.account,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    child: Text(
                      (profile?.name.isNotEmpty ?? false)
                          ? profile!.name[0].toUpperCase()
                          : '?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  title: Text(
                    profile?.name.isNotEmpty == true ? profile!.name : (session.email ?? '—'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(session.email ?? '—'),
                  // The role at a glance — the same pill the Team screen
                  // uses, so role wording stays consistent everywhere.
                  trailing: Chip(
                    avatar: const Icon(Icons.shield_outlined, size: 16),
                    label: Text(roleName),
                    visualDensity: VisualDensity.compact,
                  ),
                  onTap: () => context.push(AppRoutes.profile),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // -------------------------------------------------------- Business
          business.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(
                  e is AppException ? e.message : l10n.somethingWentWrong,
                ),
              ),
            ),
            data: (b) => SectionCard(
              title: l10n.business,
              child: Column(
                children: [
                  DetailRow(label: l10n.business, value: b?.name ?? '—'),
                  const SizedBox(height: 6),
                  DetailRow(label: l10n.currency, value: _currencyLabel(b)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ----------------------------------------------------- Preferences
          SectionCard(
            title: l10n.preferences,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.translate_outlined),
                  title: Text(l10n.language),
                  subtitle: Text(l10n.languageSubtitle),
                  trailing: Text(
                    switch (language) {
                      AppLanguage.system => l10n.languageSystem,
                      AppLanguage.english => l10n.languageEnglish,
                      AppLanguage.urdu => l10n.languageUrdu,
                    },
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  onTap: () => _pickLanguage(context, ref),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sync_outlined),
                  title: Text(l10n.syncStatus),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.syncStatus),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.notifications),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.notifications),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --------------------------------------------------------- Sign out
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context, ref),
              icon: const Icon(Icons.logout),
              label: Text(l10n.logout),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                ),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _currencyLabel(Business? business) => business?.currency ?? 'PKR';
}
