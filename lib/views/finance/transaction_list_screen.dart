import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/empty_state.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();

    final rows = [
      ...f.incomes.map(
        (v) => _Row(v.id, v.type, v.amount, v.date, true, v.paymentMethod),
      ),
      ...f.expenses.map(
        (v) => _Row(v.id, v.category, v.amount, v.date, false, v.paymentMethod),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    final results = rows
        .where(
          (x) =>
              x.title.toLowerCase().contains(query.toLowerCase()) ||
              x.method.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search transactions',
              ),
              onChanged: (v) => setState(() => query = v),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    title: 'No transactions yet',
                    icon: Icons.receipt_long,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, i) {
                      final x = results[i];
                      final uid = context.read<AuthProvider>().user?.uid;
                      return Dismissible(
                        key: ValueKey('${x.income}-${x.id}'),
                        background: Container(
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete transaction?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                        onDismissed: (_) {
                          if (uid != null) {
                            context.read<FinanceProvider>().delete(
                              uid,
                              x.income ? 'incomes' : 'expenses',
                              x.id,
                            );
                          }
                        },
                        child: ListTile(
                          leading: Icon(
                            x.income ? Icons.south_west : Icons.north_east,
                            color: x.income ? Colors.green : Colors.red,
                          ),
                          title: Text(x.title),
                          subtitle: Text('${formatDate(x.date)} · ${x.method}'),
                          trailing: Text(
                            '${x.income ? '+' : '-'}${formatCurrency(x.amount)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: x.income ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row {
  const _Row(
    this.id,
    this.title,
    this.amount,
    this.date,
    this.income,
    this.method,
  );

  final String id;
  final String title;
  final String method;
  final double amount;
  final DateTime date;
  final bool income;
}
