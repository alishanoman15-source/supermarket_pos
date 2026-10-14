import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/branch.dart';
import '../providers/branch_providers.dart';

/// Branch + POS terminal administration (SPEC §6 multi-branch, §86 screens
/// 58–59). Both lists are read straight from Supabase — RLS scopes them to the
/// caller's business and every write is gated on `branches.manage`.
class BranchListScreen extends ConsumerStatefulWidget {
  const BranchListScreen({super.key});

  @override
  ConsumerState<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends ConsumerState<BranchListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (_controller.index == 0) {
      context.push(AppRoutes.branchNew);
    } else {
      context.push(AppRoutes.terminalNew);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.branches),
        actions: [
          IconButton(
            onPressed: _add,
            icon: const Icon(Icons.add),
            tooltip: _controller.index == 0 ? l10n.addBranch : l10n.addTerminal,
          ),
        ],
        bottom: TabBar(
          controller: _controller,
          tabs: [Tab(text: l10n.branches), Tab(text: l10n.posTerminals)],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: [_BranchTab(onAdd: _add), _TerminalTab(onAdd: _add)],
      ),
    );
  }
}

class _BranchTab extends ConsumerWidget {
  final VoidCallback onAdd;

  const _BranchTab({required this.onAdd});

  static String _subtitle(Branch branch) {
    final parts = <String>[
      if (branch.address != null && branch.address!.isNotEmpty)
        branch.address!,
      if (branch.phone != null && branch.phone!.isNotEmpty) branch.phone!,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final branches = ref.watch(branchesProvider);

    return AsyncView<List<Branch>>(
      value: branches,
      onRetry: () => ref.invalidate(branchesProvider),
      builder: (rows) {
        if (rows.isEmpty) {
          return EmptyState(
            message: l10n.noBranches,
            icon: Icons.store_mall_directory_outlined,
            actionLabel: l10n.addBranch,
            onAction: onAdd,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final branch in rows)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    branch.isActive
                        ? Icons.store_mall_directory_outlined
                        : Icons.store_mall_directory_outlined,
                    color: branch.isActive ? null : Theme.of(context).colorScheme.outline,
                  ),
                  title: Text(branch.name),
                  subtitle: Text(_subtitle(branch)),
                  trailing: StatusChip(
                    status: branch.isActive ? 'active' : 'inactive',
                  ),
                  onTap: () => context.push('${AppRoutes.branches}/${branch.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TerminalTab extends ConsumerWidget {
  final VoidCallback onAdd;

  const _TerminalTab({required this.onAdd});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final terminals = ref.watch(terminalsProvider);
    final branches = ref.watch(branchesProvider).valueOrNull ?? const [];
    String branchName(String id) {
      for (final b in branches) {
        if (b.id == id) return b.name;
      }
      return '';
    }

    return AsyncView<List<PosTerminal>>(
      value: terminals,
      onRetry: () => ref.invalidate(terminalsProvider),
      builder: (rows) {
        if (rows.isEmpty) {
          return EmptyState(
            message: l10n.noTerminals,
            icon: Icons.point_of_sale_outlined,
            actionLabel: l10n.addTerminal,
            onAction: onAdd,
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final terminal in rows)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.point_of_sale_outlined),
                  title: Text(terminal.name),
                  subtitle: Text(branchName(terminal.branchId)),
                  trailing: StatusChip(status: terminal.status),
                  onTap: () =>
                      context.push('${AppRoutes.terminals}/${terminal.id}'),
                ),
              ),
          ],
        );
      },
    );
  }
}
