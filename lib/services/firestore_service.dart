import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/income_model.dart';
import '../models/expense_model.dart';
import '../models/budget_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('profile');
  }

  CollectionReference<Map<String, dynamic>> incomesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('incomes');
  }

  CollectionReference<Map<String, dynamic>> expensesCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  CollectionReference<Map<String, dynamic>> budgetsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  Future<void> addIncome(String userId, IncomeModel income) async {
    await incomesCollection(userId).add(income.toMap());
  }

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    await expensesCollection(userId).add(expense.toMap());
  }

  Future<void> setBudget(String userId, BudgetModel budget) async {
    final query = await budgetsCollection(
      userId,
    ).where('month', isEqualTo: budget.month).limit(1).get();
    if (query.docs.isEmpty) {
      await budgetsCollection(userId).add(budget.toMap());
    } else {
      await budgetsCollection(
        userId,
      ).doc(query.docs.first.id).set(budget.toMap());
    }
  }

  Stream<List<IncomeModel>> incomesStream(String userId) {
    return incomesCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IncomeModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<ExpenseModel>> expensesStream(String userId) {
    return expensesCollection(userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ExpenseModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<BudgetModel>> budgetsStream(String userId) {
    return budgetsCollection(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BudgetModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
