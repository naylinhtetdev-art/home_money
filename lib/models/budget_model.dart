import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.month,
    required this.year,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final double budgetAmount;
  final String month;
  final int year;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory BudgetModel.fromMap(String id, Map<String, dynamic> data) {
    return BudgetModel(
      id: id,
      categoryId: data['categoryId'] as String? ?? id,
      categoryName: data['categoryName'] as String? ?? 'Other',
      budgetAmount: (data['budgetAmount'] as num?)?.toDouble() ?? 0,
      month: data['month'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'categoryId': categoryId,
    'categoryName': categoryName,
    'budgetAmount': budgetAmount,
    'month': month,
    'year': year,
  };
}
