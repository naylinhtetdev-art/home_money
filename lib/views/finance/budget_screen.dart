import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('Budget')),
      body: finance.budgets.isEmpty ? const EmptyState(title: 'Set a budget to stay on track', icon: Icons.pie_chart_outline) : ListView(padding: const EdgeInsets.all(16), children: finance.budgets.map((budget) {
        final spent = budget.category == 'Monthly' ? finance.totalExpense : finance.expenses.where((e) => e.category == budget.category).fold(0.0, (sum, e) => sum + e.amount);
        final progress = spent / budget.amount;
        final remaining = (budget.amount - spent).clamp(0, budget.amount).toDouble();
        return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(budget.category, style: Theme.of(context).textTheme.titleMedium), Text(formatCurrency(budget.amount))]),
          const SizedBox(height: 12), LinearProgressIndicator(value: progress.clamp(0, 1).toDouble(), color: progress >= 1 ? Colors.red : progress >= .8 ? Colors.orange : null),
          const SizedBox(height: 8), Text(progress >= 1 ? 'Budget exceeded' : progress >= .8 ? 'Almost at your budget' : '${formatCurrency(remaining)} remaining'),
        ])));
      }).toList()),
    );
  }
  void _add(BuildContext context) {
    final amount = TextEditingController(); String category = 'Monthly';
    showDialog(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Create budget'), content: Column(mainAxisSize: MainAxisSize.min, children: [
      DropdownButtonFormField<String>(value: category, items: ['Monthly','Food','Rent','Transportation','Shopping','Education','Healthcare','Entertainment','Other'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(), onChanged: (value) => category = value!),
      const SizedBox(height: 12), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Budget amount')),
    ]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')), FilledButton(onPressed: () async { final value = double.tryParse(amount.text); if (value == null || value <= 0) return; await context.read<FinanceProvider>().saveBudget(context.read<AuthProvider>().user!.uid, BudgetModel(id: '', month: '${DateTime.now().year}-${DateTime.now().month}', amount: value, category: category, createdAt: DateTime.now())); if (dialogContext.mounted) Navigator.pop(dialogContext); }, child: const Text('Save'))]));
  }
}
