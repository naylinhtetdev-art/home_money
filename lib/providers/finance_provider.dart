import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/income_model.dart';
import '../models/saving_goal_model.dart';
import '../services/firestore_service.dart';

class FinanceProvider extends ChangeNotifier {
  final FirestoreService _store = FirestoreService();
  bool _disposed = false;
  StreamSubscription? _incomeSub;
  StreamSubscription? _expenseSub;
  StreamSubscription? _budgetSub;
  StreamSubscription? _currentBudgetSub;
  StreamSubscription? _goalSub;

  List<IncomeModel> incomes = [];
  List<ExpenseModel> expenses = [];
  List<BudgetModel> budgets = [];
  List<BudgetModel> currentMonthBudgets = [];
  List<SavingGoalModel> goals = [];
  bool loading = true;
  bool incomeSaving = false;
  bool budgetSaving = false;
  String? incomeError;
  String? budgetError;
  String? _userId;
  DateTime _budgetMonth = _monthStart(DateTime.now());

  DateTime get budgetMonth => _budgetMonth;
  String get budgetMonthKey => monthKey(_budgetMonth);
  static DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);
  static String monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  void start(String id) {
    _userId = id;
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    _budgetSub?.cancel();
    _currentBudgetSub?.cancel();
    _goalSub?.cancel();
    incomes = [];
    expenses = [];
    budgets = [];
    currentMonthBudgets = [];
    goals = [];
    loading = true;
    _notify();

    _incomeSub = _store.incomesStream(id).listen((value) {
      incomes = value;
      _done();
    });
    _expenseSub = _store.expensesStream(id).listen((value) {
      expenses = value;
      _done();
    });
    _goalSub = _store.goalsStream(id).listen((value) {
      goals = value;
      _done();
    });
    _listenToBudgets();
    _listenToCurrentMonthBudgets();
  }

  void selectBudgetMonth(DateTime month) {
    final selected = _monthStart(month);
    if (selected == _budgetMonth) return;
    _budgetMonth = selected;
    budgets = [];
    _budgetSub?.cancel();
    _listenToBudgets();
    notifyListeners();
  }

  void _listenToBudgets() {
    final userId = _userId;
    if (userId == null) return;
    _budgetSub = _store.budgetsStream(userId, budgetMonthKey).listen((value) {
      budgets = value;
      _done();
    });
  }

  void _listenToCurrentMonthBudgets() {
    final userId = _userId;
    if (userId == null) return;
    final currentMonth = _monthStart(DateTime.now());
    _currentBudgetSub = _store
        .budgetsStream(userId, monthKey(currentMonth))
        .listen((value) {
          currentMonthBudgets = value;
          _done();
        });
  }

  void _done() {
    loading = false;
    _notify();
  }

  bool _isInMonth(DateTime date, DateTime month) =>
      date.year == month.year && date.month == month.month;

  double spentForCategory(String category, DateTime month) => expenses
      .where(
        (expense) =>
            expense.category == category && _isInMonth(expense.date, month),
      )
      .fold(0, (sum, expense) => sum + expense.amount);

  double remainingFor(BudgetModel budget, DateTime month) =>
      budget.budgetAmount - spentForCategory(budget.categoryName, month);

  double usageFor(BudgetModel budget, DateTime month) {
    if (budget.budgetAmount <= 0) return 0;
    return spentForCategory(budget.categoryName, month) / budget.budgetAmount;
  }

  double get totalIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get totalExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get balance => totalIncome - totalExpense;
  double get monthlyBudget =>
      budgets.fold(0, (sum, item) => sum + item.budgetAmount);
  double get selectedMonthSpent => budgets.fold(
    0,
    (sum, item) => sum + spentForCategory(item.categoryName, _budgetMonth),
  );
  double get selectedMonthRemaining => monthlyBudget - selectedMonthSpent;
  double get currentMonthTotalBudget =>
      currentMonthBudgets.fold(0, (sum, item) => sum + item.budgetAmount);
  double get currentMonthTotalSpent {
    final month = _monthStart(DateTime.now());
    return currentMonthBudgets.fold(
      0,
      (sum, item) => sum + spentForCategory(item.categoryName, month),
    );
  }

  double get currentMonthRemaining =>
      currentMonthTotalBudget - currentMonthTotalSpent;

  Future<bool> addIncome(String id, IncomeModel item) =>
      _saveIncome(() => _store.addIncome(id, item));
  Future<bool> updateIncome(String id, IncomeModel item) =>
      _saveIncome(() => _store.updateIncome(id, item));
  Future<bool> deleteIncome(String id, String itemId) =>
      _saveIncome(() => _store.delete(id, 'incomes', itemId));

  Future<bool> _saveIncome(Future<void> Function() operation) async {
    incomeSaving = true;
    incomeError = null;
    _notify();
    try {
      await operation();
      return true;
    } catch (_) {
      incomeError =
          'Unable to save income. Please check your connection and try again.';
      return false;
    } finally {
      incomeSaving = false;
      _notify();
    }
  }

  Future<bool> saveBudget(String id, BudgetModel item) =>
      _saveBudget(() => _store.setBudget(id, item));
  Future<bool> deleteBudget(String id, BudgetModel item) =>
      _saveBudget(() => _store.deleteBudget(id, item.month, item.categoryId));

  Future<bool> _saveBudget(Future<void> Function() operation) async {
    budgetSaving = true;
    budgetError = null;
    _notify();
    try {
      await operation();
      return true;
    } catch (_) {
      budgetError =
          'Unable to save budget. Please check your connection and try again.';
      return false;
    } finally {
      budgetSaving = false;
      _notify();
    }
  }

  Future<void> addExpense(String id, ExpenseModel item) =>
      _store.addExpense(id, item);
  Future<void> saveGoal(String id, SavingGoalModel item) =>
      _store.saveGoal(id, item);
  Future<void> delete(String id, String type, String itemId) =>
      _store.delete(id, type, itemId);

  @override
  void dispose() {
    _incomeSub?.cancel();
    _expenseSub?.cancel();
    _budgetSub?.cancel();
    _currentBudgetSub?.cancel();
    _goalSub?.cancel();
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
