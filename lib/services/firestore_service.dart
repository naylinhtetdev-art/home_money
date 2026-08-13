import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/family_member_model.dart';
import '../models/income_model.dart';
import '../models/saving_goal_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentReference<Map<String, dynamic>> userDoc(String id) => _db.collection('users').doc(id);
  CollectionReference<Map<String, dynamic>> _items(String id, String name) => userDoc(id).collection(name);
  Future<void> saveProfile(UserModel user) => userDoc(user.id).set(user.toMap(), SetOptions(merge: true));
  Stream<UserModel?> profile(String id) => userDoc(id).snapshots().map((d) => d.exists ? UserModel.fromMap(d.id, d.data()!) : null);
  Stream<List<T>> _stream<T>(String id, String kind, T Function(String, Map<String, dynamic>) mapper) => _items(id, kind).orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map((d) => mapper(d.id, d.data())).toList());
  Future<void> addIncome(String id, IncomeModel value) => _items(id, 'incomes').add(value.toMap());
  Future<void> addExpense(String id, ExpenseModel value) => _items(id, 'expenses').add(value.toMap());
  Future<void> updateIncome(String id, IncomeModel value) => _items(id, 'incomes').doc(value.id).set(value.toMap());
  Future<void> updateExpense(String id, ExpenseModel value) => _items(id, 'expenses').doc(value.id).set(value.toMap());
  Future<void> delete(String id, String type, String itemId) => _items(id, type).doc(itemId).delete();
  Stream<List<IncomeModel>> incomesStream(String id) => _stream(id, 'incomes', IncomeModel.fromMap);
  Stream<List<ExpenseModel>> expensesStream(String id) => _stream(id, 'expenses', ExpenseModel.fromMap);
  Stream<List<BudgetModel>> budgetsStream(String id) => _stream(id, 'budgets', BudgetModel.fromMap);
  Stream<List<SavingGoalModel>> goalsStream(String id) => _stream(id, 'savingGoals', SavingGoalModel.fromMap);
  Stream<List<FamilyMemberModel>> familyStream(String id) => _items(id, 'familyMembers').snapshots().map((s) => s.docs.map((d) => FamilyMemberModel.fromMap(d.id, d.data())).toList());
  Future<void> setBudget(String id, BudgetModel value) => _items(id, 'budgets').doc(value.id.isEmpty ? null : value.id).set(value.toMap());
  Future<void> saveGoal(String id, SavingGoalModel value) => _items(id, 'savingGoals').doc(value.id.isEmpty ? null : value.id).set(value.toMap());
  Future<void> saveMember(String id, FamilyMemberModel value) => _items(id, 'familyMembers').doc(value.id.isEmpty ? null : value.id).set(value.toMap());
}
