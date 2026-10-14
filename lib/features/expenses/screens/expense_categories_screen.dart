import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/expense.dart';
import '../../../data/providers.dart';
import '../../auth/providers/session_controller.dart';
import '../providers/expense_providers.dart';

/// Expense category manager (SPEC §56). System categories are read-only.
class ExpenseCategoriesScreen extends ConsumerWidget {
  const ExpenseCategoriesScreen({super.key});

  Future<void> _addOrEdit(
    BuildContext context,
    WidgetRef ref, {
    String? id,
    String? initial,
  }) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: initial ?? '');
    final businessId = ref.read(sessionControllerProvider).profile?.businessId;
    if (businessId == null) return;

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? l10n.addExpenseCategory : l10n.edit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.name),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(expenseRepositoryProvider)
          .saveCategory(id: id, businessId: businessId, name: name);
      ref.invalidate(expenseCategoriesProvider);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(context,
        title: l10n.delete, message: l10n.confirmDelete, confirmLabel: l10n.delete, destructive: true);
    if (!ok) return;
    try {
      await ref.read(expenseRepositoryProvider).deleteCategory(id);
      ref.invalidate(expenseCategoriesProvider);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseCategories)),
      body: AsyncView<List<ExpenseCategory>>(
        value: categories,
        onRetry: () => ref.invalidate(expenseCategoriesProvider),
        builder: (items) => items.isEmpty
            ? EmptyState(message: l10n.noExpenseCategories, icon: Icons.category_outlined)
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = items[index];
                  return ListTile(
                    leading: Icon(
                      category.isSystem ? Icons.lock_outline : Icons.category_outlined,
                    ),
                    title: Text(category.name),
                    trailing: category.isSystem
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.edit,
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _addOrEdit(context, ref,
                                    id: category.id, initial: category.name),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(context, ref, category.id),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpenseCategory),
      ),
    );
  }
}
