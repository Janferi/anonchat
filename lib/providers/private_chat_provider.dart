import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/friendship_service.dart';

class PrivateChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final FriendshipService _friendshipService = FriendshipService();

  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get friendRequests => _friendRequests;
  List<Map<String, dynamic>> get friends => _friends;
  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;

  Future<void> loadData(String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _friendshipService.getPendingRequests(currentUserId),
        _friendshipService.getFriends(currentUserId),
        _chatService.getChatRoomsWithUsers(currentUserId),
      ]);
      _friendRequests = results[0];
      _friends = results[1];
      _chatRooms = results[2];
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest({
    required String currentUserId,
    String? phoneNumber,
    String? username,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _friendshipService.sendFriendRequest(
        currentUserId: currentUserId,
        phoneNumber: phoneNumber,
        username: username,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respondToRequest(String friendshipId, bool accept, String currentUserId) async {
    try {
      if (accept) {
        await _friendshipService.acceptFriendRequest(friendshipId);
      } else {
        await _friendshipService.rejectFriendRequest(friendshipId);
      }
      await loadData(currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  // Chat Detail Logic
  List<ChatMessage> _activeChatMessages = [];
  List<ChatMessage> get activeChatMessages => _activeChatMessages;
  StreamSubscription? _chatSubscription;
  StreamSubscription? _typingSubscription;
  Map<String, bool> _typingStatus = {};
  Map<String, bool> get typingStatus => _typingStatus;

  Future<void> enterChat(String chatRoomId, String currentUserId) async {
    _activeChatMessages = [];
    _typingStatus = {};
    _chatSubscription?.cancel();
    _typingSubscription?.cancel();

    // Load initial messages
    try {
      _activeChatMessages = await _chatService.getMessages(chatRoomId);
      notifyListeners();

      // Mark messages as read
      await _chatService.markMessagesAsRead(chatRoomId, currentUserId);

      // Subscribe to realtime messages
      _chatService.subscribeToMessages(chatRoomId);
      _chatSubscription = _chatService.messagesStream.listen(
        (messages) {
          _activeChatMessages = messages;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error receiving message: $error');
        },
        cancelOnError: false,
      );

      // Subscribe to typing status
      _chatService.subscribeToTypingStatus(chatRoomId, currentUserId);
      _typingSubscription = _chatService.typingStatusStream.listen(
        (status) {
          _typingStatus = status;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error entering chat: $e');
    }
  }

  void leaveChat() {
    _chatSubscription?.cancel();
    _typingSubscription?.cancel();
    _chatService.unsubscribeFromMessages();
    _chatService.unsubscribeFromTypingStatus();
    _activeChatMessages = [];
    _typingStatus = {};
  }

  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String messageText,
    String messageType = 'text',
  }) async {
    if (messageText.trim().isEmpty) return;

    try {
      await _chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        receiverId: receiverId,
        messageText: messageText,
        messageType: messageType,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> updateTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await _chatService.updateTypingStatus(
        chatRoomId: chatRoomId,
        userId: userId,
        isTyping: isTyping,
      );
    } catch (e) {
      debugPrint('Error updating typing status: $e');
    }
  }

  Future<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      await _friendshipService.blockUser(
        blockerId: currentUserId,
        blockedId: blockedUserId,
        reason: reason,
      );
      await loadData(currentUserId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _typingSubscription?.cancel();
    _chatService.dispose();
    super.dispose();
  }
}
