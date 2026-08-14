import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import 'auth/login_screen.dart';
import 'shell/home_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Wait for FirebaseAuth.authStateChanges() to emit its initial value.
    // Firebase restores a persisted user session before this stream reports it.
    if (!auth.loading) {
      return auth.signedIn ? const HomeShell() : const LoginScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Text(
          AppStrings.appName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
