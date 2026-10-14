import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/parties_providers.dart';

/// Creates (when [customerId] is null) or edits a customer (SPEC §45).
class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId;

  const CustomerFormScreen({super.key, this.customerId});

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _credit = TextEditingController(text: '0');

  bool _busy = false;
  bool _loading = false;

  bool get _isEdit => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final customer = await ref.read(partiesRepositoryProvider).fetchCustomer(widget.customerId!);
      if (customer != null && mounted) {
        _name.text = customer.name;
        _phone.text = customer.phone ?? '';
        _email.text = customer.email ?? '';
        _credit.text = customer.creditLimit.toString();
      }
    } on AppException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _credit]) {
      c.dispose();
    }
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
    try {
      await ref.read(partiesRepositoryProvider).saveCustomer(
            id: widget.customerId,
            businessId: businessId,
            values: {
              'name': _name.text.trim(),
              'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
              'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
              'credit_limit': _credit.text.trim().isEmpty ? '0' : _credit.text.trim(),
              'status': 'active',
            },
          );
      ref.invalidate(customersControllerProvider);
      if (_isEdit) ref.invalidate(customerProvider(widget.customerId!));
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
      appBar: AppBar(title: Text(_isEdit ? l10n.editCustomer : l10n.addCustomer)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _name,
                      label: l10n.fullName,
                      required: true,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? l10n.required : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _phone,
                      label: l10n.phone,
                      keyboardType: TextInputType.phone,
                      // Optional fields still reject malformed input so bad
                      // data never reaches the database (SPEC §96).
                      validator: (v) => Validators.phoneOptional(
                        v,
                        invalid: l10n.phoneInvalid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _email,
                      label: l10n.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => Validators.emailOptional(
                        v,
                        invalid: l10n.emailInvalid,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(controller: _address, label: l10n.address, maxLines: 2),
                    const SizedBox(height: 12),
                    AppDecimalField(
                      controller: _credit,
                      label: l10n.creditLimit,
                      requiredMessage: l10n.required,
                      invalidMessage: l10n.invalidNumber,
                    ),
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
