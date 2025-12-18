import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_user.dart';
import 'supabase_service.dart';

class UserService {
  static const String _userIdKey = 'current_user_id';
  static const String _phoneKey = 'phone_number';

  final _supabase = SupabaseService.instance;

  // Get device ID
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'ios_${DateTime.now().millisecondsSinceEpoch}';
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return windowsInfo.deviceId;
    } else {
      return 'web_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Register with phone number
  Future<ChatUser> registerWithPhone(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = await getDeviceId();

    // Check if user already exists with this phone number
    final existingUser = await _supabase.users
        .select()
        .eq('phone_number', phoneNumber)
        .maybeSingle();

    if (existingUser != null) {
      // Update user to online and device_id
      await _supabase.users
          .update({
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
            'device_id': deviceId,
          })
          .eq('id', existingUser['id']);

      final user = ChatUser.fromJson({
        ...existingUser,
        'is_online': true,
        'device_id': deviceId,
      });

      await prefs.setString(_userIdKey, user.id);
      await prefs.setString(_phoneKey, phoneNumber);
      return user;
    }

    // Create new user
    final avatarIndex = DateTime.now().millisecondsSinceEpoch % 70 + 1;
    final newUser = await _supabase.users.insert({
      'phone_number': phoneNumber,
      'device_id': deviceId,
      'avatar_url': 'https://i.pravatar.cc/150?img=$avatarIndex',
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
    }).select().single();

    final user = ChatUser.fromJson(newUser);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_phoneKey, phoneNumber);
    return user;
  }

  // Update user profile (username, avatar, bio)
  Future<ChatUser> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
    String? bio,
  }) async {
    final updateData = <String, dynamic>{};

    if (username != null) updateData['username'] = username;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (bio != null) updateData['bio'] = bio;

    if (updateData.isEmpty) {
      throw Exception('No data to update');
    }

    final updatedUser = await _supabase.users
        .update(updateData)
        .eq('id', userId)
        .select()
        .single();

    return ChatUser.fromJson(updatedUser);
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get current user
  Future<ChatUser?> getCurrentUser() async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final userData = await _supabase.users
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) return null;
    return ChatUser.fromJson(userData);
  }

  // Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _supabase.users.update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Get all users (excluding current user)
  Future<List<ChatUser>> getAllUsers({String? excludeUserId}) async {
    var query = _supabase.users.select();

    if (excludeUserId != null) {
      query = query.neq('id', excludeUserId);
    }

    final usersData = await query.order('created_at', ascending: false);
    return usersData.map((data) => ChatUser.fromJson(data)).toList();
  }

  // Get user by ID
  Future<ChatUser?> getUserById(String userId) async {
    final userData = await _supabase.users
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (userData == null) return null;
    return ChatUser.fromJson(userData);
  }

  // Search users by username
  Future<List<ChatUser>> searchUsers(String query, {String? excludeUserId}) async {
    var searchQuery = _supabase.users
        .select()
        .ilike('username', '%$query%');

    if (excludeUserId != null) {
      searchQuery = searchQuery.neq('id', excludeUserId);
    }

    final usersData = await searchQuery.order('username');
    return usersData.map((data) => ChatUser.fromJson(data)).toList();
  }

  // Logout user
  Future<void> logout() async {
    final userId = await getCurrentUserId();
    if (userId != null) {
      await updateOnlineStatus(userId, false);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }
}
