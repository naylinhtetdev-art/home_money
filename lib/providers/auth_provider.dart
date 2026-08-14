import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._auth) {
    _auth.authStateChanges().listen((user) {
      _user = user;
      _loading = false;
      notifyListeners();
    });
  }

  final AuthService _auth;
  final FirestoreService _store = FirestoreService();
  User? _user;
  bool _loading = true;
  String? error;
  User? get user => _user;
  User? get currentUser => _auth.currentUser;
  bool get loading => _loading;
  bool get signedIn => currentUser != null;
  Future<bool> login(String email, String password) =>
      _run(() => _auth.login(email.trim(), password));
  Future<bool> register(String name, String email, String password) =>
      _run(() async {
        final c = await _auth.register(name.trim(), email.trim(), password);
        await _store.saveProfile(
          UserModel(id: c.user!.uid, name: name.trim(), email: email.trim()),
        );
      });
  Future<bool> _run(Future<void> Function() action) async {
    _loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseAuthException catch (e) {
      error = _message(e.code);
      return false;
    } catch (_) {
      error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email.trim()));
  Future<void> logout() => _auth.logout();
  Future<bool> deleteAccount() => _run(() => _auth.deleteAccount());
  String _message(String code) => switch (code) {
    'invalid-credential' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already uses this email.',
    'weak-password' => 'Choose a stronger password.',
    'user-not-found' => 'No account was found for this email.',
    _ => 'Unable to complete that request. Please try again.',
  };
}
