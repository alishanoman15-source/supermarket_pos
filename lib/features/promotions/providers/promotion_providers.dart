import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/promotion.dart';
import '../../../data/providers.dart';

class PromotionsController extends PagedController<Promotion> {
  @override
  Future<List<Promotion>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(promotionRepositoryProvider).fetchPromotions(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final promotionsControllerProvider =
    AutoDisposeAsyncNotifierProvider<PromotionsController, PagedState<Promotion>>(
  PromotionsController.new,
);

final promotionProvider = FutureProvider.autoDispose.family<Promotion?, String>(
  (ref, id) => ref.watch(promotionRepositoryProvider).fetchPromotion(id),
);
