import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  // Mock backend call to request OTP
  Future<bool> requestOtp(String phoneNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would call POST /auth/otp/request
    // ignore: avoid_print
    print('OTP for $phoneNumber: 123456');
    return true;
  }

  // Mock backend call to verify OTP
  Future<UserModel> verifyOtp(String phoneNumber, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '123456') {
      // Mock OTP
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
}
