import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:home_money/services/profile_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ProfileController extends ChangeNotifier {
  final AuthService authService;
  final ProfileService profileService;
  //final ImagePicker _picker = ImagePicker();
  late final StreamSubscription<User?> _authSubscription;

  UserModel? _profile;
  UserModel? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  ProfileController({required this.authService, required this.profileService}) {
    final Stream<User?> authStateStream;
    if (authService.authStateChanges is Function) {
      authStateStream =
          (authService.authStateChanges as Function)() as Stream<User?>;
    } else {
      authStateStream = authService.authStateChanges as Stream<User?>;
    }

    _authSubscription = authStateStream.listen((user) {
      if (user != null) {
        loadProfile();
      } else {
        _profile = null;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentUser = authService.currentUser;
      if (currentUser == null) {
        _errorMessage = 'No authenticated user found.';
        return;
      }

      final storedProfile = await profileService.fetchProfile(currentUser.uid);
      if (storedProfile != null) {
        _profile = storedProfile;
      } else {
        _profile = UserModel(
          id: currentUser.uid,
          name: currentUser.displayName?.trim().isEmpty == false
              ? currentUser.displayName!
              : '',
          email: currentUser.email ?? '',
          phone: currentUser.phoneNumber ?? '',
        );
      }
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
