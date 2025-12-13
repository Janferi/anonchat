import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  // Check if user is already logged in and active
  Future<UserModel?> checkLoginStatus() async {
    final isInactive = await _storageService.checkInactivity();
    if (isInactive) {
      return null;
    }

    final phone = await _storageService.getPhoneNumber();
    if (phone != null) {
      // Restore session
      // In a real app with backend, we might validate a token here
      return UserModel(
        id: const Uuid().v4(), // Generate a transient ID or store it too
        anonHandle: 'Anon', // Placeholder, ideally stored or fetched
        consentGiven: true,
        lastActivity: DateTime.now(),
      );
    }
    return null;
  }

  Future<bool> requestOtp(String phoneNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would call POST /auth/otp/request
    // ignore: avoid_print
    print('OTP for $phoneNumber: 123456');
    return true;
  }

  Future<UserModel> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456') {
      // Save encrypted phone number
      await _storageService.savePhoneNumber(phoneNumber);

      return UserModel(
        id: const Uuid().v4(),
        anonHandle: 'Anon_${const Uuid().v4().substring(0, 4)}',
        consentGiven: true,
        lastActivity: DateTime.now(),
      );
    } else {
      throw Exception('Invalid OTP');
    }
  }

  Future<void> logout() async {
    await _storageService.clearData();
  }
}
