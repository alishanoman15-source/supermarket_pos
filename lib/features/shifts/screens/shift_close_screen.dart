import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../../../data/providers.dart';
import '../providers/shift_providers.dart';

/// Closes a shift: counted cash vs server-computed expected cash, with a
/// variance reason required outside tolerance (SPEC §14, screen #51).
class ShiftCloseScreen extends ConsumerStatefulWidget {
  final String shiftId;

  const ShiftCloseScreen({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends ConsumerState<ShiftCloseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _counted = TextEditingController();
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _counted.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      await ref.read(shiftRepositoryProvider).closeShift(
            shiftId: widget.shiftId,
            counted: Decimal.parse(_counted.text.trim()),
            varianceReason: _reason.text.trim(),
          );
      ref.invalidate(shiftsProvider);
      ref.invalidate(myOpenShiftProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saved)));
        context.pop();
      }
    } on AppException catch (e) {
      // A variance outside tolerance returns VALIDATION_FAILED asking for a reason.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final matches =
        ref.watch(shiftsProvider).valueOrNull?.where((s) => s.id == widget.shiftId).toList() ??
            const [];
    final shift = matches.isEmpty ? null : matches.first;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.closeShift)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shift != null)
                  Card(
                    child: ListTile(
                      title: Text('${l10n.openingFloat}: ${formatMoney(shift.openingFloat)}'),
                      subtitle: Text('${l10n.expectedCash}: —'),
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _counted,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l10n.countedCash),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) return l10n.required;
                    final parsed = Decimal.tryParse(v);
                    if (parsed == null || parsed < Decimal.zero) return l10n.invalidNumber;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reason,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l10n.reason,
                    helperText: l10n.varianceReasonHelp,
                  ),
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
