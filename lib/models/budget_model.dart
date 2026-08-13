import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String month;
  final double amount;
  final String category;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.amount,
    this.category = 'Monthly',
    required this.createdAt,
  });

  factory BudgetModel.fromMap(String id, Map<String, dynamic> data) {
    return BudgetModel(
      id: id,
      month: data['month'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] as String? ?? 'Monthly',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'amount': amount,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
