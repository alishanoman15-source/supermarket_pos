import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/supplier.dart';
import '../providers/parties_providers.dart';

/// Supplier list (SPEC §39) with search, pagination and pull-to-refresh.
class SupplierListScreen extends ConsumerWidget {
  const SupplierListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.suppliers)),
      body: PagedListView<Supplier>(
        provider: suppliersControllerProvider,
        searchHint: l10n.search,
        emptyMessage: l10n.noSuppliers,
        emptyIcon: Icons.local_shipping_outlined,
        emptyActionLabel: l10n.addSupplier,
        onEmptyAction: () => context.push(AppRoutes.supplierNew),
        itemBuilder: (context, supplier) => ListTile(
          leading: CircleAvatar(
            child: Text(supplier.name.isEmpty ? '?' : supplier.name.characters.first.toUpperCase()),
          ),
          title: Text(supplier.name),
          subtitle: Text([
            if (supplier.phone?.isNotEmpty == true) supplier.phone!,
            if (supplier.contactPerson?.isNotEmpty == true) supplier.contactPerson!,
          ].join(' · ')),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(money(supplier.openingBalance),
                  style: Theme.of(context).textTheme.labelLarge),
              StatusChip(status: supplier.status),
            ],
          ),
          onTap: () => context.push('${AppRoutes.suppliers}/${supplier.id}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.supplierNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addSupplier),
      ),
    );
  }
}
