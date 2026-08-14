import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore;

  ProfileService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserModel?> fetchProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserModel.fromMap(uid, snapshot.data()!);
  }

  Future<void> createOrUpdateUserDocument({
    required String uid,
    required String email,
    required String password,
    String? phoneNumber,
    String? gender,
  }) async {
    final data = <String, dynamic>{'email': email, 'password': password};

    if (phoneNumber != null) {
      data['phone_number'] = phoneNumber;
    }
    if (gender != null) {
      data['gender'] = gender;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateProfile(UserModel profile) async {
    await _firestore
        .collection('users')
        .doc(profile.id)
        .set(profile.toMap(), SetOptions(merge: true));
  }
}
