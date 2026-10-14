import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/platform_repository.dart';

/// Platform management screen for a Super Admin (SPEC §3.1): every business
/// on the platform with its branches, staff and product counts, plus branch
/// creation and super-admin grant/revoke. Guarded server-side by
/// `is_super_admin()` on every RPC — this gate is presentation only.
final adminBusinessesProvider = FutureProvider<List<AdminBusiness>>(
  (ref) => ref.watch(platformRepositoryProvider).listBusinesses(),
);

final adminBranchesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
  (ref, businessId) => ref.watch(platformRepositoryProvider).listBranches(businessId),
);

class BusinessesScreen extends ConsumerWidget {
  const BusinessesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final businesses = ref.watch(adminBusinessesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.businesses),
        actions: [
          IconButton(
            tooltip: l10n.superAdmin,
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => _superAdminDialog(context, ref),
          ),
        ],
      ),
      body: AsyncView(
        value: businesses,
        onRetry: () => ref.invalidate(adminBusinessesProvider),
        builder: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.noData));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _BusinessCard(business: list[i]),
          );
        },
      ),
    );
  }

  Future<void> _superAdminDialog(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final grant = await showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.superAdmin),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, true),
            child: Row(
              children: [
                const Icon(Icons.add_moderator_outlined),
                const SizedBox(width: 12),
                Text(l10n.grantSuperAdmin),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, false),
            child: Row(
              children: [
                const Icon(Icons.remove_moderator_outlined),
                const SizedBox(width: 12),
                Text(l10n.revokeSuperAdmin),
              ],
            ),
          ),
        ],
      ),
    );
    if (grant == null || !context.mounted) return;

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(grant ? l10n.grantSuperAdmin : l10n.revokeSuperAdmin),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.email),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
    if (email == null || email.isEmpty) return;

    try {
      final repo = ref.read(platformRepositoryProvider);
      if (grant) {
        await repo.grantSuperAdmin(email);
      } else {
        await repo.revokeSuperAdmin(email);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.saved)));
      }
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _BusinessCard extends ConsumerWidget {
  final AdminBusiness business;

  const _BusinessCard({required this.business});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final branches = ref.watch(adminBranchesProvider(business.id));

    return Card(
      child: ExpansionTile(
        leading: Icon(
          business.status == 'active'
              ? Icons.storefront_outlined
              : Icons.storefront,
          color: business.status == 'active' ? null : Theme.of(context).colorScheme.error,
        ),
        title: Text(business.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${l10n.branches}: ${business.branchCount}   •   '
          '${l10n.team}: ${business.staffCount}   •   '
          '${l10n.products}: ${business.productCount}'
          '${business.currency == null ? '' : '   •   ${business.currency}'}',
        ),
        trailing: Chip(
          label: Text(business.status == 'active' ? l10n.active : l10n.inactive),
          visualDensity: VisualDensity.compact,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: branches.when(
              data: (list) => Column(
                children: [
                  for (final branch in list)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined),
                      title: Text((branch['name'] as String?) ?? '—'),
                      subtitle: Text([
                        if ((branch['address'] as String?)?.isNotEmpty == true)
                          branch['address'] as String,
                        if ((branch['phone'] as String?)?.isNotEmpty == true)
                          branch['phone'] as String,
                      ].join(' • ')),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _createBranch(context, ref),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addBranch),
                    ),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => ListTile(
                dense: true,
                title: Text(
                  e is AppException ? e.message : l10n.somethingWentWrong,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBranch(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('${l10n.addBranch} — ${business.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.name),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    if (name == null || name.isEmpty || !context.mounted) return;

    try {
      await ref.read(platformRepositoryProvider).createBranch(
            businessId: business.id,
            name: name,
          );
      ref.invalidate(adminBranchesProvider(business.id));
      ref.invalidate(adminBusinessesProvider);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
