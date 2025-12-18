import '../models/friendship.dart';
import '../models/chat_user.dart';
import 'supabase_service.dart';

class FriendshipService {
  final _supabase = SupabaseService.instance;

  // Send friend request by phone number or username
  Future<Friendship> sendFriendRequest({
    required String currentUserId,
    String? phoneNumber,
    String? username,
  }) async {
    if (phoneNumber == null && username == null) {
      throw Exception('Phone number or username is required');
    }

    // Find user by phone or username
    ChatUser? targetUser;

    if (phoneNumber != null) {
      final users = await _supabase.users
          .select()
          .eq('phone_number', phoneNumber)
          .limit(1);
      if (users.isEmpty) {
        throw Exception('User not found with phone number');
      }
      targetUser = ChatUser.fromJson(users.first);
    } else if (username != null) {
      final users = await _supabase.users
          .select()
          .eq('username', username)
          .limit(1);
      if (users.isEmpty) {
        throw Exception('User not found with username');
      }
      targetUser = ChatUser.fromJson(users.first);
    }

    if (targetUser == null) {
      throw Exception('User not found');
    }

    // Check if user is trying to add themselves
    if (targetUser.id == currentUserId) {
      throw Exception('You cannot add yourself as a friend');
    }

    // Check if friendship already exists
    final existing = await _supabase.friendships
        .select()
        .or('and(user1_id.eq.$currentUserId,user2_id.eq.${targetUser.id}),and(user1_id.eq.${targetUser.id},user2_id.eq.$currentUserId)')
        .maybeSingle();

    if (existing != null) {
      throw Exception('Friend request already exists');
    }

    // Create friend request
    final friendship = await _supabase.friendships.insert({
      'user1_id': currentUserId,
      'user2_id': targetUser.id,
      'requester_id': currentUserId,
      'status': 'pending',
    }).select().single();

    return Friendship.fromJson(friendship);
  }

  // Accept friend request
  Future<Friendship> acceptFriendRequest(String friendshipId) async {
    final updated = await _supabase.friendships
        .update({'status': 'accepted'})
        .eq('id', friendshipId)
        .select()
        .single();

    return Friendship.fromJson(updated);
  }

  // Reject friend request
  Future<Friendship> rejectFriendRequest(String friendshipId) async {
    final updated = await _supabase.friendships
        .update({'status': 'rejected'})
        .eq('id', friendshipId)
        .select()
        .single();

    return Friendship.fromJson(updated);
  }

  // Get all friends (accepted)
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final friendships = await _supabase.friendships
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .eq('status', 'accepted');

    // Get list of blocked users
    final blockedUsers = await _supabase.userBlocks
        .select()
        .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

    final blockedUserIds = <String>{};
    for (var block in blockedUsers) {
      final blockObj = UserBlock.fromJson(block);
      // Add both blocker and blocked to exclude them from friends list
      if (blockObj.blockerId == userId) {
        blockedUserIds.add(blockObj.blockedId);
      } else {
        blockedUserIds.add(blockObj.blockerId);
      }
    }

    final List<Map<String, dynamic>> friends = [];

    for (var friendship in friendships) {
      final friendshipObj = Friendship.fromJson(friendship);
      final friendId = friendshipObj.getOtherUserId(userId);

      // Skip if this user is blocked
      if (blockedUserIds.contains(friendId)) {
        continue;
      }

      final userData = await _supabase.users
          .select()
          .eq('id', friendId)
          .single();

      friends.add({
        'friendship': friendshipObj,
        'user': ChatUser.fromJson(userData),
      });
    }

    return friends;
  }

  // Get pending friend requests (incoming)
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    final requests = await _supabase.friendships
        .select()
        .eq('user2_id', userId)
        .eq('status', 'pending');

    // Get list of blocked users
    final blockedUsers = await _supabase.userBlocks
        .select()
        .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

    final blockedUserIds = <String>{};
    for (var block in blockedUsers) {
      final blockObj = UserBlock.fromJson(block);
      // Add both blocker and blocked to exclude them from requests list
      if (blockObj.blockerId == userId) {
        blockedUserIds.add(blockObj.blockedId);
      } else {
        blockedUserIds.add(blockObj.blockerId);
      }
    }

    final List<Map<String, dynamic>> pending = [];

    for (var request in requests) {
      final friendshipObj = Friendship.fromJson(request);

      // Skip if this user is blocked
      if (blockedUserIds.contains(friendshipObj.requesterId)) {
        continue;
      }

      final userData = await _supabase.users
          .select()
          .eq('id', friendshipObj.requesterId)
          .single();

      pending.add({
        'friendship': friendshipObj,
        'user': ChatUser.fromJson(userData),
      });
    }

    return pending;
  }

  // Unfriend
  Future<void> unfriend(String friendshipId) async {
    await _supabase.friendships.delete().eq('id', friendshipId);
  }

  // Block user
  Future<UserBlock> blockUser({
    required String blockerId,
    required String blockedId,
    String? reason,
  }) async {
    // Check if already blocked
    final existing = await _supabase.userBlocks
        .select()
        .eq('blocker_id', blockerId)
        .eq('blocked_id', blockedId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('User already blocked');
    }

    final block = await _supabase.userBlocks.insert({
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'reason': reason,
    }).select().single();

    return UserBlock.fromJson(block);
  }

  // Unblock user
  Future<void> unblockUser(String blockId) async {
    await _supabase.userBlocks.delete().eq('id', blockId);
  }

  // Get blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
    final blocks = await _supabase.userBlocks
        .select()
        .eq('blocker_id', userId);

    final List<Map<String, dynamic>> blockedList = [];

    for (var block in blocks) {
      final blockObj = UserBlock.fromJson(block);

      final userData = await _supabase.users
          .select()
          .eq('id', blockObj.blockedId)
          .single();

      blockedList.add({
        'block': blockObj,
        'user': ChatUser.fromJson(userData),
      });
    }

    return blockedList;
  }

  // Report user
  Future<UserReport> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? description,
  }) async {
    final report = await _supabase.userReports.insert({
      'reporter_id': reporterId,
      'reported_id': reportedId,
      'reason': reason,
      'description': description,
    }).select().single();

    return UserReport.fromJson(report);
  }
}

