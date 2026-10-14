import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/models/branch.dart';
import '../../../data/models/expense.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../../setup/providers/branch_provider.dart';
import '../providers/expense_providers.dart';

/// Creates (when [expenseId] is null) or edits an expense (SPEC §55).
class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;

  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _payee = TextEditingController();
  final _note = TextEditingController();

  String? _categoryId;
  String? _branchId;
  DateTime _paidAt = DateTime.now();
  String _method = 'cash';
  bool _busy = false;
  bool _loading = false;

  bool get _isEdit => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _branchId = ref.read(sessionControllerProvider).profile?.branchId;
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final expense = await ref.read(expenseProvider(widget.expenseId!).future);
    if (expense != null && mounted) {
      _amount.text = expense.amount.toString();
      _categoryId = expense.categoryId;
      _branchId = expense.branchId;
      _paidAt = expense.paidAt;
      _method = expense.paymentMethod;
      _payee.text = expense.payee ?? '';
      _note.text = expense.note ?? '';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_amount, _payee, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    final profile = ref.read(sessionControllerProvider).profile;
    if (profile?.businessId == null || _branchId == null) {
      showSnack(context, l10n.errorNoBusiness);
      return;
    }

    setState(() => _busy = true);
    try {
      await ref.read(expenseRepositoryProvider).saveExpense(
            id: widget.expenseId,
            businessId: profile!.businessId!,
            branchId: _branchId!,
            values: {
              'category_id': _categoryId,
              'amount': _amount.text.trim(),
              'paid_at': _paidAt.toUtc().toIso8601String(),
              'payment_method': _method,
              'payee': _payee.text.trim().isEmpty ? null : _payee.text.trim(),
              'note': _note.text.trim().isEmpty ? null : _note.text.trim(),
              'status': 'active',
            },
          );
      ref.invalidate(expensesControllerProvider);
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
    final categories = ref.watch(expenseCategoriesProvider).valueOrNull ?? const <ExpenseCategory>[];
    final branches = ref.watch(branchesProvider).valueOrNull ?? const <Branch>[];
    final fmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editExpense : l10n.addExpense)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDecimalField(
                      controller: _amount,
                      label: l10n.amount,
                      required: true,
                      requiredMessage: l10n.required,
                      invalidMessage: l10n.invalidNumber,
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String?>(
                      label: l10n.category,
                      value: _categoryId,
                      items: [
                        for (final c in categories)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String?>(
                      label: l10n.branch,
                      required: true,
                      value: _branchId,
                      items: [
                        for (final b in branches)
                          DropdownMenuItem(value: b.id, child: Text(b.name)),
                      ],
                      onChanged: (v) => setState(() => _branchId = v),
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: l10n.paymentMethod,
                      value: _method,
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text(l10n.payCash)),
                        DropdownMenuItem(value: 'card', child: Text(l10n.payCard)),
                        DropdownMenuItem(value: 'bank_transfer', child: Text(l10n.bankTransfer)),
                        DropdownMenuItem(value: 'mobile_wallet', child: Text(l10n.payWallet)),
                        DropdownMenuItem(value: 'other', child: Text(l10n.payOther)),
                      ],
                      onChanged: (v) => setState(() => _method = v ?? 'cash'),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _paidAt,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _paidAt = picked);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.paidAt,
                          suffixIcon: const Icon(Icons.event),
                        ),
                        child: Text(fmt.format(_paidAt)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(controller: _payee, label: l10n.payee),
                    const SizedBox(height: 12),
                    AppTextField(controller: _note, label: l10n.note, maxLines: 2),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _save,
                      child: _busy
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.save),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
