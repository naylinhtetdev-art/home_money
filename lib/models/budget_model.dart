import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String month;
  final double amount;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.amount,
    required this.createdAt,
  });

  factory BudgetModel.fromMap(String id, Map<String, dynamic> data) {
    return BudgetModel(
      id: id,
      month: data['month'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
