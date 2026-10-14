import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/paged_list.dart';
import '../../../data/models/expense.dart';
import '../../../data/providers.dart';

class ExpensesController extends PagedController<Expense> {
  @override
  Future<List<Expense>> fetch({
    required int offset,
    required int limit,
    required String query,
    required Map<String, String> filters,
  }) =>
      ref.read(expenseRepositoryProvider).fetchExpenses(
            offset: offset,
            limit: limit,
            query: query,
          );
}

final expensesControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExpensesController, PagedState<Expense>>(
  ExpensesController.new,
);

final expenseCategoriesProvider = FutureProvider.autoDispose<List<ExpenseCategory>>(
  (ref) => ref.watch(expenseRepositoryProvider).fetchCategories(),
);

final expenseProvider = FutureProvider.autoDispose.family<Expense?, String>((ref, id) async {
  final page = await ref.watch(expenseRepositoryProvider).fetchExpenses(limit: 200);
  for (final e in page) {
    if (e.id == id) return e;
  }
  return null;
});
