import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoalModel {
  const SavingGoalModel({required this.id, required this.name, required this.targetAmount, required this.savedAmount, required this.targetDate, this.description = ''});
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final String description;
  double get progress => targetAmount == 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1).toDouble();
  factory SavingGoalModel.fromMap(String id, Map<String, dynamic> map) => SavingGoalModel(id: id, name: map['name'] ?? '', targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0, savedAmount: (map['savedAmount'] as num?)?.toDouble() ?? 0, targetDate: (map['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(), description: map['description'] ?? '');
  Map<String, dynamic> toMap() => {'name': name, 'targetAmount': targetAmount, 'savedAmount': savedAmount, 'targetDate': Timestamp.fromDate(targetDate), 'description': description, 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()};
}
