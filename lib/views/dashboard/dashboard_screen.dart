import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/helpers.dart';
import '../finance/add_transaction_screen.dart';
import '../finance/budget_screen.dart';
import '../finance/transaction_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _startedFor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final finance = context.watch<FinanceProvider>();

    // Start listening to finance streams when user becomes available
    if (auth.user != null && _startedFor != auth.user!.uid) {
      _startedFor = auth.user!.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<FinanceProvider>().start(_startedFor!);
      });
    }

    final greeting = DateTime.now().hour < 12 ? 'morning' : 'afternoon';

    // Build recent activities (combine incomes and expenses)
    final activities = [
      ...finance.incomes.map(
        (i) => _Activity(i.type, i.amount, i.date, true, i.paymentMethod),
      ),
      ...finance.expenses.map(
        (e) => _Activity(e.category, e.amount, e.date, false, e.paymentMethod),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Good $greeting'),
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TransactionListScreen(),
                  ),
                ),
                icon: const Icon(Icons.receipt_long),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  formatMonthYear(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _BalanceCard(
                  income: finance.totalIncome,
                  expense: finance.totalExpense,
                ),
                if (finance.currentMonthBudgets.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _MonthlyBudgetSummary(finance: finance),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    _Quick(
                      icon: Icons.add_card,
                      label: 'Income',
                      color: Colors.green,
                      onTap: () => _openAdd(true),
                    ),
                    const SizedBox(width: 10),
                    _Quick(
                      icon: Icons.remove_circle,
                      label: 'Expense',
                      color: Colors.red,
                      onTap: () => _openAdd(false),
                    ),
                    const SizedBox(width: 10),
                    _Quick(
                      icon: Icons.pie_chart,
                      label: 'Budget',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BudgetScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionListScreen(),
                        ),
                      ),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (finance.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (activities.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No recent activity'),
                    ),
                  )
                else
                  ...activities.take(6).map((a) => _TransactionTile(item: a)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openAdd(bool income) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddTransactionScreen(income: income)),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.income, required this.expense});

  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available balance',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _stat('Income', income)),
              Expanded(child: _stat('Expenses', expense)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, double value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(color: Colors.white70)),
      Text(
        formatCurrency(value),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _Quick extends StatelessWidget {
  const _Quick({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyBudgetSummary extends StatelessWidget {
  const _MonthlyBudgetSummary({required this.finance});

  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    final month = DateTime(DateTime.now().year, DateTime.now().month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly budget summary',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...finance.currentMonthBudgets.map((budget) {
              final spent = finance.spentForCategory(
                budget.categoryName,
                month,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(budget.categoryName),
                        Text(
                          '${formatCurrency(spent)} / ${formatCurrency(budget.budgetAmount)}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value:
                          (budget.budgetAmount == 0
                                  ? 0
                                  : spent / budget.budgetAmount)
                              .clamp(0, 1)
                              .toDouble(),
                      color: spent > budget.budgetAmount ? Colors.red : null,
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            _totalRow('Total budget', finance.currentMonthTotalBudget),
            _totalRow('Total spent', finance.currentMonthTotalSpent),
            _totalRow('Total remaining', finance.currentMonthRemaining),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, double amount) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _Activity {
  const _Activity(this.title, this.amount, this.date, this.income, this.method);

  final String title;
  final double amount;
  final DateTime date;
  final bool income;
  final String method;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final _Activity item;

  @override
  Widget build(BuildContext context) {
    final color = item.income ? Colors.green : Colors.red;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(
          item.income ? Icons.arrow_downward : Icons.arrow_upward,
          color: color,
        ),
      ),
      title: Text(item.title),
      subtitle: Text('${formatDate(item.date)} · ${item.method}'),
      trailing: Text(
        '${item.income ? '+' : '-'}${formatCurrency(item.amount)}',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
