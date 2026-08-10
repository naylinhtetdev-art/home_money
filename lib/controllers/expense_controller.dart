import 'package:home_money/models/expense_model.dart';
import 'package:home_money/services/firestore_service.dart';

class ExpenseController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> addExpense(String userId, ExpenseModel expense) async {
    await _firestoreService.addExpense(userId, expense);
  }
}
