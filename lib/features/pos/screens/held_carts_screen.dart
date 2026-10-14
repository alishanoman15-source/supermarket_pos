import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/utils/money.dart';
import '../providers/cart_controller.dart';
import '../providers/pos_providers.dart';

/// Held carts for this device (SPEC §10 step 8, screen #17).
class HeldCartsScreen extends ConsumerWidget {
  const HeldCartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final held = ref.watch(heldCartsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.heldCarts)),
      body: held.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.somethingWentWrong)),
        data: (carts) {
          if (carts.isEmpty) return Center(child: Text(l10n.noHeldCarts));
          return ListView.separated(
            itemCount: carts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final cart = carts[index];
              return ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: Text(cart.label),
                subtitle: Text(
                  '${cart.cart.lineCount} · ${formatMoney(cart.cart.grandTotal)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.delete,
                  onPressed: () =>
                      ref.read(heldCartsControllerProvider.notifier).remove(cart.id),
                ),
                onTap: () {
                  ref.read(cartControllerProvider.notifier).restore(cart.cart);
                  ref.read(heldCartsControllerProvider.notifier).remove(cart.id);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
