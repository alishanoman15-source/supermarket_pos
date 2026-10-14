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

/// Brand list (SPEC §25) with inline edit / archive.
class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  Future<void> _archive(BuildContext context, WidgetRef ref, Brand brand) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(context,
        title: l10n.archive, message: l10n.confirmDelete, confirmLabel: l10n.archive);
    if (!ok) return;
    try {
      await ref.read(catalogRepositoryProvider).deactivateBrand(brand.id);
      ref.invalidate(brandsProvider);
    } on AppException catch (e) {
      if (context.mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brands = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.brands)),
      body: AsyncView<List<Brand>>(
        value: brands,
        onRetry: () => ref.invalidate(brandsProvider),
        builder: (items) => items.isEmpty
            ? EmptyState(message: l10n.noResults, icon: Icons.local_offer_outlined)
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final brand = items[index];
                  return ListTile(
                    title: Text(brand.name),
                    onTap: () => context.push('${AppRoutes.brandEdit}/${brand.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: l10n.edit,
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => context.push('${AppRoutes.brandEdit}/${brand.id}'),
                        ),
                        IconButton(
                          tooltip: l10n.archive,
                          icon: const Icon(Icons.archive_outlined),
                          onPressed: () => _archive(context, ref, brand),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.brandNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addBrand),
      ),
    );
  }
}
