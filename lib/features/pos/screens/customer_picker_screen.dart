import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../providers/cart_controller.dart';
import '../providers/pos_providers.dart';

/// Customer picker for the POS (SPEC §10 step 4, screen #13). Guests are
/// allowed; selecting a customer attaches loyalty accrual server-side.
class CustomerPickerScreen extends ConsumerStatefulWidget {
  const CustomerPickerScreen({super.key});

  @override
  ConsumerState<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends ConsumerState<CustomerPickerScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final customers = ref.watch(customerSearchProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customer)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: l10n.searchCustomer,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_off_outlined),
            title: Text(l10n.guestCustomer),
            onTap: () {
              ref.read(cartControllerProvider.notifier).setCustomer(null);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: customers.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(error is AppException ? error.message : l10n.somethingWentWrong),
              ),
              data: (items) {
                if (items.isEmpty) return Center(child: Text(l10n.noResults));
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = items[index];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(customer.name),
                      subtitle: Text([
                        if (customer.phone != null) customer.phone!,
                        if (customer.email != null) customer.email!,
                      ].join('  ·  ')),
                      trailing: Text(formatQty(customer.loyaltyPoints)),
                      onTap: () {
                        ref.read(cartControllerProvider.notifier).setCustomer(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
