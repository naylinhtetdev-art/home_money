import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/budget_model.dart'; import '../models/expense_model.dart'; import '../models/income_model.dart'; import '../models/saving_goal_model.dart'; import '../services/firestore_service.dart';
class FinanceProvider extends ChangeNotifier {
  final FirestoreService _store = FirestoreService(); StreamSubscription? _incomeSub, _expenseSub, _budgetSub, _goalSub;
  List<IncomeModel> incomes = []; List<ExpenseModel> expenses = []; List<BudgetModel> budgets = []; List<SavingGoalModel> goals = []; bool loading = true;
  void start(String id) { _incomeSub?.cancel(); _incomeSub = _store.incomesStream(id).listen((v) { incomes=v; _done(); }); _expenseSub = _store.expensesStream(id).listen((v) { expenses=v; _done(); }); _budgetSub = _store.budgetsStream(id).listen((v) { budgets=v; _done(); }); _goalSub = _store.goalsStream(id).listen((v) { goals=v; _done(); }); }
  void _done() { loading = false; notifyListeners(); }
  double get totalIncome => incomes.fold(0, (a, b) => a + b.amount); double get totalExpense => expenses.fold(0, (a,b) => a+b.amount); double get balance => totalIncome-totalExpense; double get monthlyBudget => budgets.fold(0, (a,b)=>a+b.amount);
  Future<void> addIncome(String id, IncomeModel item) => _store.addIncome(id,item); Future<void> addExpense(String id, ExpenseModel item) => _store.addExpense(id,item); Future<void> saveBudget(String id, BudgetModel item) => _store.setBudget(id,item); Future<void> saveGoal(String id, SavingGoalModel item) => _store.saveGoal(id,item); Future<void> delete(String id, String type, String itemId) => _store.delete(id,type,itemId);
  @override void dispose() { _incomeSub?.cancel(); _expenseSub?.cancel(); _budgetSub?.cancel(); _goalSub?.cancel(); super.dispose(); }
}
