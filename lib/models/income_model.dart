import 'package:cloud_firestore/cloud_firestore.dart';

class IncomeModel {
  final String id;
  final double amount;
  final String source;
  final DateTime date;
  final String note;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;

  IncomeModel({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    required this.note,
    this.paymentMethod = 'Cash',
    required this.createdAt,
    this.updatedAt,
  });

  // Keeps existing dashboard/report code compatible while new documents use
  // the clearer Firestore field name, `source`.
  String get type => source;

  factory IncomeModel.fromMap(String id, Map<String, dynamic> data) {
    return IncomeModel(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      source: (data['source'] ?? data['type']) as String? ?? 'Other',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? 'Cash',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'source': source,
      'date': Timestamp.fromDate(date),
      'note': note,
      'paymentMethod': paymentMethod,
    };
  }
}
