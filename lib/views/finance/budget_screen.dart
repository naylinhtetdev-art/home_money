import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const _categories = [
    'Food',
    'Rent',
    'Electricity',
    'Water',
    'Internet',
    'Phone',
    'Transportation',
    'Education',
    'Healthcare',
    'Shopping',
    'Entertainment',
    'Family',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final month = finance.budgetMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: finance.budgetSaving ? null : () => _editBudget(context),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(formatMonthYear(month)),
              onPressed: () => _pickMonth(context, month),
            ),
          ),
          _MonthSummary(finance: finance),
          Expanded(
            child: finance.budgets.isEmpty
                ? const EmptyState(
                    title: 'Set a category budget for this month',
                    icon: Icons.pie_chart_outline,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: finance.budgets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final budget = finance.budgets[index];
                      return _BudgetCard(
                        budget: budget,
                        spent: finance.spentForCategory(
                          budget.categoryName,
                          month,
                        ),
                        onEdit: () => _editBudget(context, budget: budget),
                        onDelete: () => _deleteBudget(context, budget),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context, DateTime current) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select budget month',
    );
    if (selected != null && context.mounted) {
      context.read<FinanceProvider>().selectBudgetMonth(selected);
    }
  }

  Future<void> _editBudget(BuildContext context, {BudgetModel? budget}) async {
    final amount = TextEditingController(
      text: budget == null ? '' : budget.budgetAmount.toString(),
    );
    var month = budget == null
        ? context.read<FinanceProvider>().budgetMonth
        : _dateForMonth(budget.month, budget.year);
    var category = budget?.categoryName ?? _categories.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(budget == null ? 'Set category budget' : 'Edit budget'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Month'),
                  subtitle: Text(formatMonthYear(month)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final selected = await showDatePicker(
                      context: dialogContext,
                      initialDate: month,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (selected != null) {
                      setDialogState(
                        () => month = DateTime(selected.year, selected.month),
                      );
                    }
                  },
                ),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'Expense category',
                  ),
                  items: _categories
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: budget == null
                      ? (value) => setDialogState(() => category = value!)
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Budget amount'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            Consumer<FinanceProvider>(
              builder: (_, finance, _) => FilledButton(
                onPressed: finance.budgetSaving
                    ? null
                    : () => _saveBudget(
                        context,
                        dialogContext,
                        month,
                        category,
                        amount.text,
                      ),
                child: finance.budgetSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
    amount.dispose();
  }

  Future<void> _saveBudget(
    BuildContext parentContext,
    BuildContext dialogContext,
    DateTime month,
    String category,
    String amountText,
  ) async {
    final amount = double.tryParse(amountText.trim());
    final user = parentContext.read<AuthProvider>().user;
    if (user == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('Enter a valid budget amount.')),
      );
      return;
    }

    final finance = parentContext.read<FinanceProvider>();
    // Prevent double save if already saving
    if (finance.budgetSaving) return;

    final item = BudgetModel(
      id: _categoryId(category),
      categoryId: _categoryId(category),
      categoryName: category,
      budgetAmount: amount,
      month: FinanceProvider.monthKey(month),
      year: month.year,
      createdAt: DateTime.now(),
    );
    final saved = await finance.saveBudget(user.uid, item);
    if (!parentContext.mounted) return;
    if (!saved) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(
          content: Text(finance.budgetError ?? 'Unable to save budget.'),
        ),
      );
      return;
    }
    finance.selectBudgetMonth(month);
    if (Navigator.of(dialogContext).canPop()) Navigator.pop(dialogContext);
    ScaffoldMessenger.of(
      parentContext,
    ).showSnackBar(const SnackBar(content: Text('Budget saved')));
  }

  Future<void> _deleteBudget(BuildContext context, BudgetModel budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete budget?'),
        content: Text('Remove the ${budget.categoryName} budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final finance = context.read<FinanceProvider>();
    final deleted = await finance.deleteBudget(user.uid, budget);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted
              ? 'Budget deleted'
              : (finance.budgetError ?? 'Unable to delete budget.'),
        ),
      ),
    );
  }

  static DateTime _dateForMonth(String month, int year) {
    final parts = month.split('-');
    return DateTime(
      parts.isNotEmpty ? int.tryParse(parts.first) ?? year : year,
      parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1,
    );
  }

  static String _categoryId(String category) => category
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.finance});

  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _value('Total budget', finance.monthlyBudget),
          _value('Total spent', finance.selectedMonthSpent),
          _value('Remaining', finance.selectedMonthRemaining),
        ],
      ),
    ),
  );

  Widget _value(String label, double amount) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Text(
        formatCurrency(amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetModel budget;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final remaining = budget.budgetAmount - spent;
    final usage = budget.budgetAmount == 0 ? 0.0 : spent / budget.budgetAmount;
    final overBudget = remaining < 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.categoryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            Text('Budget: ${formatCurrency(budget.budgetAmount)}'),
            Text('Spent: ${formatCurrency(spent)}'),
            Text(
              overBudget
                  ? 'Over budget: ${formatCurrency(-remaining)}'
                  : 'Remaining: ${formatCurrency(remaining)}',
              style: TextStyle(
                color: overBudget ? Colors.red : null,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: usage.clamp(0, 1).toDouble(),
              color: overBudget
                  ? Colors.red
                  : usage >= .8
                  ? Colors.orange
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              '${(usage * 100).round()}% used',
              style: TextStyle(color: overBudget ? Colors.red : null),
            ),
          ],
        ),
      ),
    );
  }
}
