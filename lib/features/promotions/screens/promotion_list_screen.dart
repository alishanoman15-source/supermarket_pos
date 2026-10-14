import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/promotion.dart';
import '../providers/promotion_providers.dart';

/// Promotion list (SPEC §57).
class PromotionListScreen extends ConsumerWidget {
  const PromotionListScreen({super.key});

  String _typeLabel(BuildContext context, String type) {
    final l10n = context.l10n;
    switch (type) {
      case 'percent_off':
        return l10n.percentOff;
      case 'fixed_off':
        return l10n.fixedOff;
      case 'buy_x_get_y':
        return l10n.buyXGetY;
      case 'price_per_unit':
        return l10n.pricePerUnit;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fmt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.promotions)),
      body: PagedListView<Promotion>(
        provider: promotionsControllerProvider,
        searchHint: l10n.search,
        emptyMessage: l10n.noPromotions,
        emptyIcon: Icons.local_offer_outlined,
        emptyActionLabel: l10n.addPromotion,
        onEmptyAction: () => context.push(AppRoutes.promotionNew),
        itemBuilder: (context, promo) => ListTile(
          leading: const Icon(Icons.local_offer_outlined),
          title: Text(promo.name),
          subtitle: Text([
            _typeLabel(context, promo.promoType),
            promo.value == Decimal.zero ? null : money(promo.value),
            if (promo.endsAt != null) fmt.format(promo.endsAt!),
          ].whereType<String>().join(' · ')),
          trailing: StatusChip(
            status: promo.isLive ? 'active' : 'inactive',
            label: promo.isLive ? l10n.active : l10n.inactive,
          ),
          onTap: () => context.push('${AppRoutes.promotions}/${promo.id}/edit'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.promotionNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addPromotion),
      ),
    );
  }
}
