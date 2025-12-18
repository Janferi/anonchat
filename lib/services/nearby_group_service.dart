import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/nearby_group.dart';
import '../models/chat_user.dart';
import 'supabase_service.dart';

class NearbyGroupService {
  final _supabase = SupabaseService.instance;

  // Stream controllers
  final _groupMessagesController = StreamController<List<GroupMessage>>.broadcast();
  Stream<List<GroupMessage>> get groupMessagesStream => _groupMessagesController.stream;

  RealtimeChannel? _groupMessagesChannel;

  // Create nearby group
  Future<NearbyGroup> createGroup({
    required String creatorId,
    required String name,
    String? description,
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
    int maxMembers = 50,
  }) async {
    final groupData = await _supabase.nearbyGroups.insert({
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'max_members': maxMembers,
      'is_active': true,
    }).select().single();

    final group = NearbyGroup.fromJson(groupData);

    // Auto-join creator as admin
    await joinGroup(groupId: group.id, userId: creatorId, role: 'admin');

    return group;
  }

  // Get nearby groups based on user location
  Future<List<NearbyGroup>> getNearbyGroups({
    required double latitude,
    required double longitude,
    int maxDistanceMeters = 5000,
  }) async {
    final result = await SupabaseService.client.rpc(
      'get_nearby_groups',
      params: {
        'user_lat': latitude,
        'user_lon': longitude,
        'max_distance_meters': maxDistanceMeters,
      },
    );

    final List<NearbyGroup> groups = [];
    for (var item in result as List) {
      final groupData = await _supabase.nearbyGroups
          .select()
          .eq('id', item['group_id'])
          .single();

      groups.add(NearbyGroup.fromJson(groupData));
    }

    return groups;
  }

  // Join group
  Future<GroupMember> joinGroup({
    required String groupId,
    required String userId,
    String role = 'member',
  }) async {
    // Check if already a member
    final existing = await _supabase.groupMembers
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      return GroupMember.fromJson(existing);
    }

    // Check group member limit
    final members = await _supabase.groupMembers
        .select()
        .eq('group_id', groupId);

    final groupData = await _supabase.nearbyGroups
        .select()
        .eq('id', groupId)
        .single();

    final group = NearbyGroup.fromJson(groupData);

    if (members.length >= group.maxMembers) {
      throw Exception('Group is full');
    }

    final memberData = await _supabase.groupMembers.insert({
      'group_id': groupId,
      'user_id': userId,
      'role': role,
    }).select().single();

    return GroupMember.fromJson(memberData);
  }

  // Leave group
  Future<void> leaveGroup({
    required String groupId,
    required String userId,
  }) async {
    await _supabase.groupMembers
        .delete()
        .eq('group_id', groupId)
        .eq('user_id', userId);
  }

  // Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final members = await _supabase.groupMembers
        .select()
        .eq('group_id', groupId);

    final List<Map<String, dynamic>> membersList = [];

    for (var member in members) {
      final memberObj = GroupMember.fromJson(member);

      final userData = await _supabase.users
          .select()
          .eq('id', memberObj.userId)
          .single();

      membersList.add({
        'member': memberObj,
        'user': ChatUser.fromJson(userData),
      });
    }

    return membersList;
  }

  // Send group message
  Future<GroupMessage> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String messageText,
    String messageType = 'text',
  }) async {
    // Check if user is member
    final isMember = await _supabase.groupMembers
        .select()
        .eq('group_id', groupId)
        .eq('user_id', senderId)
        .maybeSingle();

    if (isMember == null) {
      throw Exception('You must be a member to send messages');
    }

    final messageData = await _supabase.groupMessages.insert({
      'group_id': groupId,
      'sender_id': senderId,
      'message_text': messageText,
      'message_type': messageType,
    }).select().single();

    return GroupMessage.fromJson(messageData);
  }

  // Get group messages
  Future<List<GroupMessage>> getGroupMessages(String groupId) async {
    final messagesData = await _supabase.groupMessages
        .select()
        .eq('group_id', groupId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    return messagesData.map((data) => GroupMessage.fromJson(data)).toList();
  }

  // Subscribe to group messages realtime
  void subscribeToGroupMessages(String groupId) {
    _groupMessagesChannel?.unsubscribe();

    _groupMessagesChannel = _supabase.channel('group_messages:$groupId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'group_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'group_id',
          value: groupId,
        ),
        callback: (payload) async {
          final messages = await getGroupMessages(groupId);
          _groupMessagesController.add(messages);
        },
      )
      ..subscribe();
  }

  // Unsubscribe from group messages
  void unsubscribeFromGroupMessages() {
    _groupMessagesChannel?.unsubscribe();
    _groupMessagesChannel = null;
  }

  // Delete group (only creator can delete)
  Future<void> deleteGroup({
    required String groupId,
    required String userId,
  }) async {
    final groupData = await _supabase.nearbyGroups
        .select()
        .eq('id', groupId)
        .single();

    final group = NearbyGroup.fromJson(groupData);

    if (group.creatorId != userId) {
      throw Exception('Only the creator can delete the group');
    }

    await _supabase.nearbyGroups.delete().eq('id', groupId);
  }

  // Cleanup
  void dispose() {
    unsubscribeFromGroupMessages();
    _groupMessagesController.close();
  }
}
