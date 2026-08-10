import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_money/services/auth_service.dart';

class AuthController {
  final AuthService _authService = AuthService();

  User? get currentUser => _authService.currentUser;

  Stream<User?> get authStateChanges => _authService.authStateChanges();

  Future<UserCredential> login(String email, String password) async {
    return await _authService.login(email, password);
  }

  Future<UserCredential> register(
    String name,
    String email,
    String password,
  ) async {
    return await _authService.register(name, email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
  }

  Future<void> resetPassword(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }
}
