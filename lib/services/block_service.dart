import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  static const String _keyBlockedUsers = 'blocked_users';

  Future<List<String>> getBlockedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyBlockedUsers) ?? [];
  }

  Future<void> blockUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList(_keyBlockedUsers) ?? [];
    if (!blocked.contains(userId)) {
      blocked.add(userId);
      await prefs.setStringList(_keyBlockedUsers, blocked);
    }
  }

  Future<void> unblockUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = prefs.getStringList(_keyBlockedUsers) ?? [];
    if (blocked.contains(userId)) {
      blocked.remove(userId);
      await prefs.setStringList(_keyBlockedUsers, blocked);
    }
  }

  Future<bool> isUserBlocked(String userId) async {
    final blocked = await getBlockedUsers();
    return blocked.contains(userId);
  }
}
