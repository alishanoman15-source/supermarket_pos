import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/branch_providers.dart';

/// Create/edit a branch (SPEC §6, §86 screen #58). Writes are authorised by
/// the `branches.manage` RLS policy — the client cannot bypass it.
class BranchFormScreen extends ConsumerStatefulWidget {
  final String? id;

  const BranchFormScreen({super.key, this.id});

  @override
  ConsumerState<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends ConsumerState<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  String _status = 'active';
  bool _busy = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  void _prefill() {
    final rows = ref.read(branchesProvider).valueOrNull ?? const [];
    for (final row in rows) {
      if (row.id == widget.id) {
        _name.text = row.name;
        _address.text = row.address ?? '';
        _phone.text = row.phone ?? '';
        _status = row.isActive ? 'active' : 'inactive';
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (businessId == null) {
      showSnack(context, l10n.errorNoBusiness);
      return;
    }

    setState(() => _busy = true);
    final repo = ref.read(businessRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateBranch(
          id: widget.id!,
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
          status: _status,
        );
      } else {
        await repo.createBranch(
          businessId: businessId,
          name: _name.text,
          address: _address.text,
          phone: _phone.text,
        );
      }
      ref.invalidate(branchesProvider);
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

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editBranch : l10n.addBranch)),
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
            AppTextField(
              controller: _address,
              label: l10n.address,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _phone,
              label: l10n.phone,
              keyboardType: TextInputType.phone,
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
