import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/promotion_providers.dart';

/// Creates (when [promotionId] is null) or edits a promotion (SPEC §58).
class PromotionFormScreen extends ConsumerStatefulWidget {
  final String? promotionId;

  const PromotionFormScreen({super.key, this.promotionId});

  @override
  ConsumerState<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends ConsumerState<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _value = TextEditingController(text: '0');
  final _minQty = TextEditingController(text: '0');
  final _freeQty = TextEditingController(text: '0');

  String _type = 'percent_off';
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _stackable = false;
  bool _busy = false;
  bool _loading = false;

  bool get _isEdit => widget.promotionId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final promo = await ref.read(promotionProvider(widget.promotionId!).future);
    if (promo != null && mounted) {
      _name.text = promo.name;
      _type = promo.promoType;
      _value.text = promo.value.toString();
      _minQty.text = promo.minQty.toString();
      _freeQty.text = promo.freeQty.toString();
      _startsAt = promo.startsAt;
      _endsAt = promo.endsAt;
      _stackable = promo.isStackable;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final c in [_name, _value, _minQty, _freeQty]) {
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
      await ref.read(promotionRepositoryProvider).savePromotion(
            id: widget.promotionId,
            businessId: businessId,
            values: {
              'name': _name.text.trim(),
              'promo_type': _type,
              'value': _value.text.trim().isEmpty ? '0' : _value.text.trim(),
              'min_qty': _minQty.text.trim().isEmpty ? '0' : _minQty.text.trim(),
              'free_qty': _freeQty.text.trim().isEmpty ? '0' : _freeQty.text.trim(),
              'starts_at': _startsAt?.toUtc().toIso8601String(),
              'ends_at': _endsAt?.toUtc().toIso8601String(),
              'is_stackable': _stackable,
              'status': 'active',
            },
          );
      ref.invalidate(promotionsControllerProvider);
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
    final fmt = DateFormat.yMMMd();
    final showsQty = _type == 'buy_x_get_y';

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editPromotion : l10n.addPromotion)),
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
                      label: l10n.name,
                      required: true,
                      validator: (v) => (v?.trim().isEmpty ?? true) ? l10n.required : null,
                    ),
                    const SizedBox(height: 12),
                    AppDropdown<String>(
                      label: l10n.promoType,
                      value: _type,
                      items: [
                        DropdownMenuItem(value: 'percent_off', child: Text(l10n.percentOff)),
                        DropdownMenuItem(value: 'fixed_off', child: Text(l10n.fixedOff)),
                        DropdownMenuItem(value: 'buy_x_get_y', child: Text(l10n.buyXGetY)),
                        DropdownMenuItem(value: 'price_per_unit', child: Text(l10n.pricePerUnit)),
                      ],
                      onChanged: (v) => setState(() => _type = v ?? 'percent_off'),
                    ),
                    const SizedBox(height: 12),
                    AppDecimalField(
                      controller: _value,
                      label: l10n.value,
                      requiredMessage: l10n.required,
                      invalidMessage: l10n.invalidNumber,
                    ),
                    if (showsQty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppDecimalField(controller: _minQty, label: l10n.minQty),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppDecimalField(controller: _freeQty, label: l10n.freeQty),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppDateField(
                            label: l10n.startsAt,
                            value: _startsAt,
                            onChanged: (v) => setState(() => _startsAt = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppDateField(
                            label: l10n.endsAt,
                            value: _endsAt,
                            onChanged: (v) => setState(() => _endsAt = v),
                          ),
                        ),
                      ],
                    ),
                    if (_startsAt != null || _endsAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${_startsAt == null ? '—' : fmt.format(_startsAt!)} → '
                          '${_endsAt == null ? '—' : fmt.format(_endsAt!)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    SwitchListTile(
                      value: _stackable,
                      onChanged: (v) => setState(() => _stackable = v),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.stackable),
                    ),
                    const SizedBox(height: 16),
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
