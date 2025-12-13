import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';

class StorageService {
  static const String _keyPhone = 'user_phone';
  static const String _keyAuthTime = 'auth_timestamp';
  static const String _keyConsent = 'consent_accepted';

  // In a real app, this key should be stored in Android Keystore / iOS Keychain
  // For this assignment, we use a generated key or specific key for AES
  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;

  StorageService() {
    // using a fixed key for demo stability across restarts without secure storage
    // In production, this must be securely generated and stored
    _key = Key.fromUtf8('AnonChatSecureKey32Characters!!!');
    _iv = IV.fromLength(16);
    _encrypter = Encrypter(AES(_key));
  }

  Future<void> savePhoneNumber(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = _encrypter.encrypt(phone, iv: _iv);
    await prefs.setString(_keyPhone, encrypted.base64);
    await prefs.setInt(_keyAuthTime, DateTime.now().millisecondsSinceEpoch);
  }

  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedBase64 = prefs.getString(_keyPhone);

    if (encryptedBase64 == null) return null;

    try {
      final encrypted = Encrypted.fromBase64(encryptedBase64);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyAuthTime);
    await prefs.remove(_keyConsent);
  }

  Future<bool> checkInactivity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuth = prefs.getInt(_keyAuthTime);
    if (lastAuth == null) return true; // Treat as inactive if no timestamp

    final lastDate = DateTime.fromMillisecondsSinceEpoch(lastAuth);
    final difference = DateTime.now().difference(lastDate);

    if (difference.inDays >= 30) {
      await clearData();
      return true; // Data wiped, user inactive
    }

    // Update timestamp on active access
    await prefs.setInt(_keyAuthTime, DateTime.now().millisecondsSinceEpoch);
    return false;
  }

  Future<void> setConsentAccepted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyConsent, value);
  }

  Future<bool> isConsentAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyConsent) ?? false;
  }
}
