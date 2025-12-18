import 'package:flutter/material.dart';
import '../models/chat_user.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final UserService _userService = UserService();
  ChatUser? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  ChatUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.id;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _userService.getCurrentUser();
      if (_user != null) {
        // Update online status
        await _userService.updateOnlineStatus(_user!.id, true);
      }
    } catch (e) {
      print('Auth check failed: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> registerWithPhone(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _userService.registerWithPhone(phoneNumber);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    if (_user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _user = await _userService.updateProfile(
        userId: _user!.id,
        username: username,
        avatarUrl: avatarUrl,
        bio: bio,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    if (_user != null) {
      await _userService.updateOnlineStatus(_user!.id, false);
    }
    await _userService.logout();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_user != null) {
      final refreshedUser = await _userService.getUserById(_user!.id);
      if (refreshedUser != null) {
        _user = refreshedUser;
        notifyListeners();
      }
    }
  }
}
