import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.income,
    this.incomeToEdit,
  }) : assert(income || incomeToEdit == null);

  final bool income;
  final IncomeModel? incomeToEdit;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();

  static const List<String> _incomeCategories = [
    'Salary',
    'Business',
    'Freelance',
    'Bonus',
    'Investment',
    'Other',
  ];

  static const List<String> _expenseCategories = [
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

  static const List<String> _paymentMethods = [
    'Cash',
    'Bank',
    'KBZPay',
    'WavePay',
    'Card',
    'Other',
  ];

  late String _category;
  String _method = _paymentMethods.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    _category = widget.income
        ? _incomeCategories.first
        : _expenseCategories.first;
    final income = widget.incomeToEdit;
    if (income != null) {
      _amountCtrl.text = income.amount.toString();
      _noteCtrl.text = income.note;
      _category = income.source;
      _method = income.paymentMethod;
      _date = income.date;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      }
      return;
    }

    final finance = context.read<FinanceProvider>();
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    if (widget.income) {
      final previous = widget.incomeToEdit;
      final item = IncomeModel(
        id: previous?.id ?? '',
        amount: amount,
        source: _category,
        date: _date,
        note: _noteCtrl.text.trim(),
        paymentMethod: _method,
        createdAt: previous?.createdAt ?? DateTime.now(),
        updatedAt: previous?.updatedAt,
      );
      final saved = previous == null
          ? await finance.addIncome(user.uid, item)
          : await finance.updateIncome(user.uid, item);
      if (!mounted) return;
      if (!saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(finance.incomeError ?? 'Unable to save income'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(previous == null ? 'Income saved' : 'Income updated'),
        ),
      );
      Navigator.of(context).pop();
      return;
    } else {
      final item = ExpenseModel(
        id: '',
        amount: amount,
        category: _category,
        date: _date,
        note: _noteCtrl.text.trim(),
        paymentMethod: _method,
        createdAt: DateTime.now(),
      );
      await finance.addExpense(user.uid, item);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction saved')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final savingIncome =
        widget.income && context.watch<FinanceProvider>().incomeSaving;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.incomeToEdit != null
              ? 'Edit Income'
              : widget.income
              ? 'Add Income'
              : 'Add Expense',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final n = double.tryParse(v.trim());
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Amount must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                items: (widget.income ? _incomeCategories : _expenseCategories)
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
                decoration: InputDecoration(
                  labelText: widget.income ? 'Source' : 'Category',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _method,
                items: _paymentMethods
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _method = v);
                },
                decoration: const InputDecoration(labelText: 'Payment Method'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: savingIncome ? null : _save,
                child: savingIncome
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
