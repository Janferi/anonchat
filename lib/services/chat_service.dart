import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import 'supabase_service.dart';

class ChatService {
  final _supabase = SupabaseService.instance;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _typingChannel;

  // Stream controllers
  final _messagesController = StreamController<List<ChatMessage>>.broadcast();
  final _typingStatusController = StreamController<Map<String, bool>>.broadcast();

  Stream<List<ChatMessage>> get messagesStream => _messagesController.stream;
  Stream<Map<String, bool>> get typingStatusStream => _typingStatusController.stream;

  // Create or get chat room between two users
  Future<ChatRoom> getOrCreateChatRoom(String user1Id, String user2Id) async {
    // Cek apakah room sudah ada (bisa user1->user2 atau user2->user1)
    final existingRoom = await _supabase.chatRooms
        .select()
        .or('and(user1_id.eq.$user1Id,user2_id.eq.$user2Id),and(user1_id.eq.$user2Id,user2_id.eq.$user1Id)')
        .maybeSingle();

    if (existingRoom != null) {
      return ChatRoom.fromJson(existingRoom);
    }

    // Create new room
    final newRoom = await _supabase.chatRooms.insert({
      'user1_id': user1Id,
      'user2_id': user2Id,
    }).select().single();

    return ChatRoom.fromJson(newRoom);
  }

  // Get all chat rooms for a user with last message
  Future<List<Map<String, dynamic>>> getChatRoomsWithUsers(String userId) async {
    final rooms = await _supabase.chatRooms
        .select('*, messages(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_message_at', ascending: false);

    // Get list of blocked users by current user
    final blockedUsersData = await _supabase.userBlocks
        .select('blocked_id')
        .eq('blocker_id', userId);

    final blockedUserIds = blockedUsersData.map((block) => block['blocked_id'] as String).toSet();

    final List<Map<String, dynamic>> roomsWithUsers = [];

    for (var room in rooms) {
      final roomData = ChatRoom.fromJson(room);
      final otherUserId = roomData.getOtherUserId(userId);

      // Skip if other user is blocked by current user
      if (blockedUserIds.contains(otherUserId)) {
        continue;
      }

      // Get other user data
      final userData = await _supabase.users
          .select()
          .eq('id', otherUserId)
          .single();

      final otherUser = ChatUser.fromJson(userData);

      // Get last message
      final messages = room['messages'] as List;
      ChatMessage? lastMessage;

      if (messages.isNotEmpty) {
        messages.sort((a, b) => DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at'])));
        lastMessage = ChatMessage.fromJson(messages.first);
      }

      // Count unread messages
      final unreadResponse = await _supabase.messages
          .select('id')
          .eq('chat_room_id', roomData.id)
          .eq('receiver_id', userId)
          .eq('is_read', false);

      final unreadCount = unreadResponse.length;

      roomsWithUsers.add({
        'room': roomData,
        'otherUser': otherUser,
        'lastMessage': lastMessage,
        'unreadCount': unreadCount,
      });
    }

    return roomsWithUsers;
  }

  // Send message
  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String messageText,
    String messageType = 'text',
  }) async {
    final messageData = await _supabase.messages.insert({
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message_text': messageText,
      'message_type': messageType,
      'is_read': false,
    }).select().single();

    return ChatMessage.fromJson(messageData);
  }

  // Get messages in a chat room
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    final messagesData = await _supabase.messages
        .select()
        .eq('chat_room_id', chatRoomId)
        .eq('is_deleted', false)
        .order('created_at', ascending: true);

    return messagesData.map((data) => ChatMessage.fromJson(data)).toList();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    await _supabase.messages
        .update({'is_read': true})
        .eq('chat_room_id', chatRoomId)
        .eq('receiver_id', userId)
        .eq('is_read', false);
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    await _supabase.messages
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  // Subscribe to messages in realtime
  void subscribeToMessages(String chatRoomId) {
    _messagesChannel?.unsubscribe();

    _messagesChannel = _supabase.channel('messages:$chatRoomId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_room_id',
          value: chatRoomId,
        ),
        callback: (payload) async {
          // Reload all messages
          final messages = await getMessages(chatRoomId);
          _messagesController.add(messages);
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_room_id',
          value: chatRoomId,
        ),
        callback: (payload) async {
          final messages = await getMessages(chatRoomId);
          _messagesController.add(messages);
        },
      )
      ..subscribe();
  }

  // Unsubscribe from messages
  void unsubscribeFromMessages() {
    _messagesChannel?.unsubscribe();
    _messagesChannel = null;
  }

  // Update typing status
  Future<void> updateTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    await _supabase.typingStatus.upsert({
      'chat_room_id': chatRoomId,
      'user_id': userId,
      'is_typing': isTyping,
    });
  }

  // Subscribe to typing status
  void subscribeToTypingStatus(String chatRoomId, String currentUserId) {
    _typingChannel?.unsubscribe();

    _typingChannel = _supabase.channel('typing:$chatRoomId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'typing_status',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_room_id',
          value: chatRoomId,
        ),
        callback: (payload) async {
          // Get typing status for other users
          final typingData = await _supabase.typingStatus
              .select()
              .eq('chat_room_id', chatRoomId)
              .neq('user_id', currentUserId);

          final typingStatus = <String, bool>{};
          for (var data in typingData) {
            typingStatus[data['user_id']] = data['is_typing'] ?? false;
          }

          _typingStatusController.add(typingStatus);
        },
      )
      ..subscribe();
  }

  // Unsubscribe from typing status
  void unsubscribeFromTypingStatus() {
    _typingChannel?.unsubscribe();
    _typingChannel = null;
  }

  // Cleanup
  void dispose() {
    unsubscribeFromMessages();
    unsubscribeFromTypingStatus();
    _messagesController.close();
    _typingStatusController.close();
  }
}
