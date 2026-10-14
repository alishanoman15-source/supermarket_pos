import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/team.dart';
import '../../../data/providers.dart';
// Prefixed: team_providers.dart exports its own `permissionsProvider` (the
// permission *catalogue*), while this prefix exposes the signed-in role's
// AccessPolicy provider.
import '../../auth/providers/permissions_controller.dart' as auth;
import '../../auth/providers/session_controller.dart';
import '../providers/team_providers.dart';

/// Employees & roles admin (SPEC §65). Members get a role; roles own the
/// permission grants. Both are enforced server-side by RLS.
class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  /// Creates an auth account for a new employee through the `staff-invite`
  /// edge function (SPEC §83) and assigns their role.
  Future<void> _invite() async {
    final l10n = context.l10n;
    // Await the roles instead of reading a possibly-still-loading value:
    // a cold read returned an empty list, which made every dialog that
    // offers a role picker unusable.
    final List<AppRole> roles;
    try {
      roles = await ref.read(rolesProvider.future);
    } catch (_) {
      if (mounted) showSnack(context, l10n.somethingWentWrong);
      return;
    }
    if (roles.isEmpty) {
      if (mounted) showSnack(context, l10n.somethingWentWrong);
      return;
    }

    final email = TextEditingController();
    final name = TextEditingController();
    String roleId = roles.first.id;
    String roleKey = roles.first.key;

    final formKey = GlobalKey<FormState>();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.inviteStaff),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppTextField(
                    controller: name,
                    label: l10n.name,
                    required: true,
                    autofocus: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? l10n.required : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: email,
                    label: l10n.email,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    // A malformed address never reaches the staff-invite
                    // edge function (SPEC §4).
                    validator: (v) => Validators.email(
                      v,
                      required: l10n.emailRequired,
                      invalid: l10n.emailInvalid,
                    ),
                  ),
                const SizedBox(height: 12),
                AppDropdown<String>(
                  label: l10n.role,
                  value: roleId,
                  items: [
                    for (final role in roles)
                      DropdownMenuItem(value: role.id, child: Text(role.name)),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      roleId = v;
                      roleKey = roles
                          .firstWhere((r) => r.id == v,
                              orElse: () => roles.first)
                          .key;
                    });
                  },
                ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                // Run every field validator before accepting the dialog.
                if (!(formKey.currentState?.validate() ?? false)) return;
                Navigator.pop(context, true);
              },
              child: Text(l10n.inviteStaff),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(teamRepositoryProvider).inviteMember(
            email: email.text.trim(),
            name: name.text.trim(),
            roleId: roleId,
            roleKey: roleKey.isEmpty ? null : roleKey,
          );
      ref.invalidate(teamProvider);
      if (mounted) showSnack(context, l10n.inviteSent);
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      email.dispose();
      name.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Roles & permissions are owner territory: a manager may open the team
    // (users.manage) but only roles.manage holders get the editor tab.
    // Postgres refuses the writes regardless — RLS on `roles` checks
    // roles.manage — so this is UI honesty, not the security boundary.
    final canManageRoles =
        ref.watch(auth.accessPolicyProvider).can('roles.manage');
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.team),
        actions: [
          IconButton(
            tooltip: l10n.inviteStaff,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _invite,
          ),
        ],
        bottom: canManageRoles
            ? TabBar(
                controller: _tabs,
                tabs: [
                  Tab(text: l10n.employees),
                  Tab(text: l10n.permissions),
                ],
              )
            : null,
      ),
      body: canManageRoles
          ? TabBarView(
              controller: _tabs,
              children: const [
                _MembersTab(),
                _RolesTab(),
              ],
            )
          : const _MembersTab(),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  Future<void> _assignRole(BuildContext context, WidgetRef ref, TeamMember member) async {
    final l10n = context.l10n;
    // Await the role catalogue: reading it cold returned an empty list, so
    // the dropdown had zero items and the role could never be changed.
    final List<AppRole> roles;
    try {
      roles = await ref.read(rolesProvider.future);
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.somethingWentWrong);
      return;
    }
    if (roles.isEmpty) {
      if (context.mounted) showSnack(context, l10n.somethingWentWrong);
      return;
    }
    String? selected = member.roleId;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(l10n.assignRole),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Make it obvious which employee is being changed.
                Text(
                  member.name.isEmpty ? '—' : member.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  member.roleName ?? '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: selected,
                  decoration: InputDecoration(labelText: l10n.role),
                  items: [
                    for (final role in roles)
                      DropdownMenuItem(value: role.id, child: Text(role.name)),
                  ],
                  onChanged: (v) => setState(() => selected = v),
                ),
              ],
            ),          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
            // Saving without a chosen role would be a silent no-op — keep
            // the button disabled until something is selected.
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
    if (ok != true || selected == null) return;
    try {
      await ref.read(teamRepositoryProvider).assignRole(profileId: member.id, roleId: selected!);
      ref.invalidate(teamProvider);
      if (context.mounted) showSnack(context, l10n.saved);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  /// Activates / deactivates a staff account (SPEC §66). A deactivated
  /// profile fails `has_permission()` server-side, so the person cannot use
  /// the app even with a valid login session — and the login screen tells
  /// them why. The signed-in user cannot deactivate themselves.
  Future<void> _toggleStatus(
      BuildContext context, WidgetRef ref, TeamMember member) async {
    final l10n = context.l10n;
    final myId = ref.read(sessionControllerProvider).profile?.id;
    if (member.isActive && member.id == myId) {
      showSnack(context, l10n.cannotDeactivateSelf);
      return;
    }
    if (member.isActive) {
      final ok = await confirmDialog(
        context,
        title: l10n.deactivateMember,
        message: l10n.deactivateMemberConfirm,
        confirmLabel: l10n.deactivateMember,
        destructive: true,
      );
      if (!ok) return;
    }
    try {
      await ref.read(teamRepositoryProvider).updateMember(
            profileId: member.id,
            status: member.isActive ? 'inactive' : 'active',
          );
      ref.invalidate(teamProvider);
      if (context.mounted) {
        showSnack(
            context, member.isActive ? l10n.memberDeactivated : l10n.memberActivated);
      }
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  /// Sets a new password for a member's auth account (SPEC §66).
  ///
  /// Invited staff can lose the password chosen while accepting the invite;
  /// email reset links only work once SMTP/redirects are configured, so the
  /// owner resets it here and passes it on out-of-band.
  Future<void> _resetPassword(
      BuildContext context, WidgetRef ref, TeamMember member) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetPassword),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name} — ${member.roleName ?? ''}'.trim(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.resetPasswordFor,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  obscureText: true,
                  decoration: InputDecoration(labelText: l10n.newPassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.passwordRequired;
                    if (v.length < 8) return l10n.passwordTooShort;
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final password = controller.text;
    controller.dispose();
    if (saved != true) return;

    try {
      await ref.read(teamRepositoryProvider).resetMemberPassword(
            userId: member.id,
            password: password,
          );
      if (context.mounted) showSnack(context, l10n.passwordResetDone);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final team = ref.watch(teamProvider);
    // Keep the role catalogue alive while the tab is on screen so the
    // assign-role / invite dialogs open with a populated picker.
    ref.watch(rolesProvider);
    return AsyncView<List<TeamMember>>(
      value: team,
      onRetry: () => ref.invalidate(teamProvider),
      builder: (members) => members.isEmpty
          ? EmptyState(message: l10n.noEmployees, icon: Icons.people_outline)
          : ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(member.name.isEmpty
                        ? '?'
                        : member.name.characters.first.toUpperCase()),
                  ),
                  title: Text(member.name),
                  subtitle: Text(member.roleName ?? l10n.assignRole),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(status: member.status),
                      PopupMenuButton<String>(
                        tooltip: l10n.more,
                        onSelected: (action) {
                          if (action == 'role') {
                            _assignRole(context, ref, member);
                          } else if (action == 'status') {
                            _toggleStatus(context, ref, member);
                          } else if (action == 'password') {
                            _resetPassword(context, ref, member);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'role',
                            child: Text(l10n.assignRole),
                          ),
                          PopupMenuItem(
                            value: 'status',
                            child: Text(member.isActive
                                ? l10n.deactivateMember
                                : l10n.activateMember),
                          ),
                          PopupMenuItem(
                            value: 'password',
                            child: Text(l10n.resetPassword),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _assignRole(context, ref, member),
                );
              },
            ),
    );
  }
}

class _RolesTab extends ConsumerWidget {
  const _RolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final roles = ref.watch(rolesProvider);
    return AsyncView<List<AppRole>>(
      value: roles,
      onRetry: () => ref.invalidate(rolesProvider),
      builder: (items) => ListView(
        children: [
          for (final role in items)
            ListTile(
              leading: Icon(role.isSystem ? Icons.shield_outlined : Icons.badge_outlined),
              title: Text(role.name),
              subtitle: Text(role.description ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openEditor(context, ref, role: role),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: Text(l10n.roleName),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, {AppRole? role}) async {
    final l10n = context.l10n;
    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (businessId == null) return;

    final name = TextEditingController(text: role?.name ?? '');
    final description = TextEditingController(text: role?.description ?? '');
    // Await the permission catalogue — a cold read showed an empty
    // checkbox list in the role editor.
    final List<AppPermission> permissions;
    try {
      permissions = await ref.read(permissionsProvider.future);
    } catch (_) {
      if (context.mounted) showSnack(context, l10n.somethingWentWrong);
      return;
    }
    Set<String> selected = {};
    if (role != null) {
      selected = Set.of(await ref.read(rolePermissionKeysProvider(role.id).future));
    }

    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final grouped = <String, List<AppPermission>>{};
          for (final permission in permissions) {
            grouped.putIfAbsent(permission.category, () => []).add(permission);
          }
          return AlertDialog(
            title: Text(role == null ? l10n.roleName : l10n.edit),
            content: SizedBox(
              width: 480,
              height: 520,
              child: Column(
                children: [
                  AppTextField(controller: name, label: l10n.roleName),
                  const SizedBox(height: 8),
                  AppTextField(controller: description, label: l10n.note),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final entry in grouped.entries) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(entry.key.toUpperCase(),
                                style: Theme.of(context).textTheme.labelLarge),
                          ),
                          for (final permission in entry.value)
                            CheckboxListTile(
                              value: selected.contains(permission.key),
                              dense: true,
                              title: Text(permission.key),
                              subtitle: Text(permission.description),
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  selected.add(permission.key);
                                } else {
                                  selected.remove(permission.key);
                                }
                              }),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
    name.dispose();
    description.dispose();
    if (saved != true) return;

    try {
      await ref.read(teamRepositoryProvider).saveRole(
            id: role?.id,
            businessId: businessId,
            name: nameOr(role, name),
            description: description.text.trim(),
            permissionKeys: selected,
          );
      ref.invalidate(rolesProvider);
      if (context.mounted) showSnack(context, l10n.roleSaved);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  String nameOr(AppRole? role, TextEditingController controller) =>
      controller.text.trim().isEmpty ? (role?.name ?? 'Role') : controller.text.trim();
}
