import '../../models/income_model.dart';
import '../../services/firestore_service.dart';

class IncomeController {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> addIncome(String userId, IncomeModel income) async {
    await _firestoreService.addIncome(userId, income);
  }
}
