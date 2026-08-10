import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String id;
  final double amount;
  final String type;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  IncomeModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.note,
    required this.createdAt,
  });

  factory IncomeModel.fromMap(String id, Map<String, dynamic> data) {
    return IncomeModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] as String? ?? 'Other',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
