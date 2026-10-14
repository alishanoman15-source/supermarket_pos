import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/async_view.dart';
import '../../../data/models/category.dart';
import '../../../data/providers.dart';
import '../providers/catalog_providers.dart';

/// Category list (SPEC §23) with inline edit / archive.
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  Future<void> _archive(BuildContext context, WidgetRef ref, Category category) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(context,
        title: l10n.archive, message: l10n.confirmDelete, confirmLabel: l10n.archive);
    if (!ok) return;
    try {
      await ref.read(catalogRepositoryProvider).deactivateCategory(category.id);
      ref.invalidate(categoriesProvider);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      body: AsyncView<List<Category>>(
        value: categories,
        onRetry: () => ref.invalidate(categoriesProvider),
        builder: (items) => items.isEmpty
            ? EmptyState(message: l10n.noResults, icon: Icons.category_outlined)
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final category = items[index];
                  return ListTile(
                    title: Text(category.name),
                    onTap: () =>
                        context.push('${AppRoutes.categoryEdit}/${category.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.push('${AppRoutes.categoryEdit}/${category.id}'),
                        ),
                        IconButton(
                          tooltip: l10n.archive,
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => _archive(context, ref, category),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.categoryNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCategory),
      ),
    );
  }
}
