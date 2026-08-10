import 'package:home_money/models/budget_model.dart';
import 'package:home_money/services/firestore_service.dart';

class BudgetController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> setBudget(String userId, BudgetModel budget) async {
    await _firestoreService.setBudget(userId, budget);
  }
}
