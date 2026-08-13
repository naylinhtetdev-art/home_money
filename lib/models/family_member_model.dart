class FamilyMemberModel {
  const FamilyMemberModel({required this.id, required this.name, required this.role, this.income = 0, this.expenses = 0, this.imageUrl});
  final String id, name, role;
  final double income, expenses;
  final String? imageUrl;
  factory FamilyMemberModel.fromMap(String id, Map<String, dynamic> m) => FamilyMemberModel(id: id, name: m['name'] ?? '', role: m['role'] ?? 'Other', income: (m['income'] as num?)?.toDouble() ?? 0, expenses: (m['expenses'] as num?)?.toDouble() ?? 0, imageUrl: m['imageUrl']);
  Map<String, dynamic> toMap() => {'name': name, 'role': role, 'income': income, 'expenses': expenses, 'imageUrl': imageUrl};
}
