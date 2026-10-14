import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/branch.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/branch_providers.dart';

/// Create/edit a POS terminal (SPEC §77, §86 screen #59). Gated server-side by
/// the `branches.manage` RLS policy on `pos_terminals`.
class TerminalFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const TerminalFormScreen({super.key, this.id});

  @override
  ConsumerState<TerminalFormScreen> createState() => _TerminalFormScreenState();
}

class _TerminalFormScreenState extends ConsumerState<TerminalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _branchId;
  String _status = 'active';
  bool _busy = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  void _prefill() {
    final rows = ref.read(terminalsProvider).valueOrNull ?? const [];
    for (final row in rows) {
      if (row.id == widget.id) {
        _name.text = row.name;
        _branchId = row.branchId;
        _status = row.status;
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final branchId = _branchId;
    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (branchId == null) {
      showSnack(context, l10n.required);
      return;
    }
    if (businessId == null) {
      showSnack(context, l10n.errorNoBusiness);
      return;
    }

    setState(() => _busy = true);
    final repo = ref.read(businessRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateTerminal(
          id: widget.id!,
          branchId: branchId,
          name: _name.text,
          status: _status,
        );
      } else {
        await repo.createTerminal(
          businessId: businessId,
          branchId: branchId,
          name: _name.text,
        );
      }
      ref.invalidate(terminalsProvider);
      if (mounted) {
        showSnack(context, l10n.saved);
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final branches = ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editTerminal : l10n.addTerminal)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _name,
              label: l10n.name,
              required: true,
              autofocus: !_isEdit,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.required : null,
            ),
            const SizedBox(height: 12),
            AppDropdown<String>(
              label: l10n.branch,
              value: _branchId,
              required: true,
              items: [
                for (final branch in branches)
                  DropdownMenuItem(value: branch.id, child: Text(branch.name)),
              ],
              onChanged: (v) => setState(() => _branchId = v),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              AppDropdown<String>(
                label: l10n.status,
                value: _status,
                items: [
                  DropdownMenuItem(value: 'active', child: Text(l10n.active)),
                  DropdownMenuItem(
                      value: 'inactive', child: Text(l10n.inactive)),
                ],
                onChanged: (v) => setState(() => _status = v ?? 'active'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? l10n.loading : l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
