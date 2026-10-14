import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/catalog_providers.dart';

enum TaxonomyKind { category, brand }

/// Category form (SPEC §24) / Brand form (SPEC §26).
class TaxonomyFormScreen extends ConsumerStatefulWidget {
  final TaxonomyKind kind;
  final String? id;

  const TaxonomyFormScreen({super.key, required this.kind, this.id});

  @override
  ConsumerState<TaxonomyFormScreen> createState() => _TaxonomyFormScreenState();
}

class _TaxonomyFormScreenState extends ConsumerState<TaxonomyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _busy = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  void _prefill() {
    if (widget.kind == TaxonomyKind.category) {
      final items = ref.read(categoriesProvider).valueOrNull ?? const [];
      for (final item in items) {
        if (item.id == widget.id) _name.text = item.name;
      }
    } else {
      final items = ref.read(brandsProvider).valueOrNull ?? const [];
      for (final item in items) {
        if (item.id == widget.id) _name.text = item.name;
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
    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (businessId == null) {
      showSnack(context, l10n.errorNoBusiness);
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(catalogRepositoryProvider);
    try {
      if (widget.kind == TaxonomyKind.category) {
        if (_isEdit) {
          await repo.updateCategory(widget.id!, _name.text);
        } else {
          await repo.createCategory(businessId: businessId, name: _name.text);
        }
        ref.invalidate(categoriesProvider);
      } else {
        if (_isEdit) {
          await repo.updateBrand(widget.id!, _name.text);
        } else {
          await repo.createBrand(businessId: businessId, name: _name.text);
        }
        ref.invalidate(brandsProvider);
      }
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
    final isCategory = widget.kind == TaxonomyKind.category;
    final title = isCategory
        ? (_isEdit ? l10n.editCategory : l10n.addCategory)
        : (_isEdit ? l10n.editBrand : l10n.addBrand);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
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
                autofocus: true,
                validator: (v) => (v?.trim().isEmpty ?? true) ? l10n.required : null,
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
