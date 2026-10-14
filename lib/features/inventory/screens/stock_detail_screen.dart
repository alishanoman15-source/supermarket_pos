import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/inventory.dart';
import '../providers/inventory_providers.dart';

/// Product stock detail: on-hand summary + movement timeline (screen #29).
class StockDetailScreen extends ConsumerWidget {
  final String productId;

  const StockDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final record = ref.watch(stockRecordProvider(productId));
    final movements = ref.watch(stockMovementsProvider(productId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventory)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.stockAdjust}/$productId'),
        icon: const Icon(Icons.tune),
        label: Text(l10n.adjustStock),
      ),
      body: ListView(
        children: [
          record.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(e is AppException ? e.message : l10n.somethingWentWrong, textAlign: TextAlign.center),
            ),
            data: (stock) {
              if (stock == null) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noResults, textAlign: TextAlign.center),
                );
              }
              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(stock.name, style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text([
                    '${l10n.sku}: ${stock.sku ?? '—'}',
                    '${l10n.reorderLevel}: ${formatQty(stock.reorderLevel)}',
                  ].join('\n')),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatQty(stock.onHand),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: stock.isLow ? Colors.orange : null,
                            ),
                      ),
                      if (stock.isLow) Text(l10n.lowStock, style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(l10n.movements, style: Theme.of(context).textTheme.titleLarge),
          ),
          movements.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text(e is AppException ? e.message : l10n.somethingWentWrong, textAlign: TextAlign.center),
            ),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.noResults, textAlign: TextAlign.center),
                  )
                : Column(
                    children: [for (final movement in items) _MovementTile(movement: movement)],
                  ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final StockMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final positive = movement.qtyDelta > Decimal.zero;
    return ListTile(
      dense: true,
      leading: Icon(
        positive ? Icons.arrow_downward : Icons.arrow_upward,
        color: positive ? Colors.green : Colors.red,
      ),
      title: Text(_typeLabel(context, movement.movementType)),
      subtitle: Text([
        '${movement.qtyBefore} → ${movement.qtyAfter}',
        if (movement.reason != null && movement.reason!.isNotEmpty) movement.reason!,
        movement.createdAt.toString().substring(0, 16),
      ].join(' · ')),
      trailing: Text(
        '${positive ? '+' : ''}${movement.qtyDelta}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  String _typeLabel(BuildContext context, String type) {
    switch (type) {
      case 'sale':
        return 'Sale';
      case 'sale_return':
        return 'Return';
      case 'purchase':
        return 'Purchase';
      case 'adjustment':
        return context.l10n.adjustStock;
      case 'count_correction':
        return 'Count correction';
      case 'transfer_in':
        return 'Transfer in';
      case 'transfer_out':
        return 'Transfer out';
      case 'opening':
        return 'Opening';
      default:
        return type;
    }
  }
}
