import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_router.dart';
import '../../../core/ui/app_widgets.dart';
import '../../../core/ui/paged_list.dart';
import '../../../data/models/expense.dart';
import '../providers/expense_providers.dart';

/// Expense list (SPEC §54) with search, pagination and totals.
class ExpenseListScreen extends ConsumerWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final dt = DateFormat.yMMMd();
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenses),
        actions: [
          IconButton(
            tooltip: l10n.expenseCategories,
            icon: const Icon(Icons.category_outlined),
            onPressed: () => context.push(AppRoutes.expenseCategories),
          ),
        ],
      ),
      body: PagedListView<Expense>(
        provider: expensesControllerProvider,
        searchHint: l10n.search,
        emptyMessage: l10n.noExpenses,
        emptyIcon: Icons.payments_outlined,
        emptyActionLabel: l10n.addExpense,
        onEmptyAction: () => context.push(AppRoutes.expenseNew),
        itemBuilder: (context, expense) => ListTile(
          leading: const Icon(Icons.receipt_outlined),
          title: Text(expense.categoryName ?? l10n.expense),
          subtitle: Text([
            dt.format(expense.paidAt),
            expense.paymentMethod.replaceAll('_', ' '),
            if (expense.payee?.isNotEmpty == true) expense.payee!,
          ].join(' · ')),
          trailing: Text(money(expense.amount), style: Theme.of(context).textTheme.titleSmall),
          onTap: () => context.push('${AppRoutes.expenses}/${expense.id}/edit'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.expenseNew),
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
    );
  }
}
