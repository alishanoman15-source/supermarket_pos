import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/customer.dart';
import '../providers/parties_providers.dart';

/// Customer list (SPEC §43) with search, pagination and pull-to-refresh.
class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customers)),
      body: PagedListView<Customer>(
        provider: customersControllerProvider,
        searchHint: l10n.searchCustomer,
        emptyMessage: l10n.noCustomers,
        emptyIcon: Icons.people_outline,
        emptyActionLabel: l10n.addCustomer,
        onEmptyAction: () => context.push(AppRoutes.customerNew),
        itemBuilder: (context, customer) => ListTile(
          leading: CircleAvatar(
            child: Text(customer.name.isEmpty ? '?' : customer.name.characters.first.toUpperCase()),
          ),
          title: Text(customer.name),
          subtitle: Text([
            if (customer.phone?.isNotEmpty == true) customer.phone!,
            if (customer.email?.isNotEmpty == true) customer.email!,
          ].join(' · ')),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${formatQty(customer.loyaltyPoints)} ${l10n.points}',
                  style: Theme.of(context).textTheme.labelLarge),
              Text(money(customer.creditLimit),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          onTap: () => context.push('${AppRoutes.customers}/${customer.id}'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.customerNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addCustomer),
      ),
    );
  }
}
