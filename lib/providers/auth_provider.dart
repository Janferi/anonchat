import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> requestOtp(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.requestOtp(phoneNumber);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.verifyOtp(phoneNumber, otp);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? anonHandle,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      _user = _user!.copyWith(
        displayName: displayName,
        bio: bio,
        anonHandle: anonHandle,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _user = null;
    notifyListeners();
  }
}
