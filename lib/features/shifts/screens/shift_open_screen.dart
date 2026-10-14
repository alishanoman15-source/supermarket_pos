import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/providers.dart';
import '../providers/shift_providers.dart';

/// Opens a shift with an opening float (SPEC §14).
class ShiftOpenScreen extends ConsumerStatefulWidget {
  const ShiftOpenScreen({super.key});

  @override
  ConsumerState<ShiftOpenScreen> createState() => _ShiftOpenScreenState();
}

class _ShiftOpenScreenState extends ConsumerState<ShiftOpenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _float = TextEditingController(text: '0');
  bool _busy = false;

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(shiftRepositoryProvider).openShift(
            openingFloat: Decimal.parse(_float.text.trim()),
          );
      ref.invalidate(shiftsProvider);
      ref.invalidate(myOpenShiftProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
        context.pop();
      }
    } on AppException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.openShift)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _float,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.openingFloat),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return l10n.required;
                    final parsed = Decimal.tryParse(v);
                    if (parsed == null || parsed < Decimal.zero) return l10n.invalidNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
