class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String currency;
  final String language;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.currency = 'MMK',
    this.language = 'en',
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      currency: data['currency'] as String? ?? 'MMK',
      language: data['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'currency': currency,
      'language': language,
      'updatedAt': DateTime.now(),
    };
  }
}
