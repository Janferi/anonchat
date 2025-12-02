import 'dart:async';
import 'package:flutter/material.dart';
import '../models/friend_request_model.dart';
import '../models/private_chat_model.dart';
import '../models/message_model.dart';
import '../services/private_chat_service.dart';

class PrivateChatProvider with ChangeNotifier {
  final PrivateChatService _service = PrivateChatService();

  List<FriendRequestModel> _requests = [];
  List<PrivateChatModel> _chats = [];
  bool _isLoading = false;

  List<FriendRequestModel> get requests => _requests;
  List<PrivateChatModel> get chats => _chats;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.getFriendRequests(),
        _service.getPrivateChats(),
      ]);
      _requests = results[0] as List<FriendRequestModel>;
      _chats = results[1] as List<PrivateChatModel>;
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String phoneNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _service.sendFriendRequest(phoneNumber);
      // In real app, maybe show success message
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    try {
      await _service.respondToRequest(requestId, accept);
      await loadData(); // Reload to update lists
    } catch (e) {
      rethrow;
    }
  }

  // Chat Detail Logic
  List<MessageModel> _activeChatMessages = [];
  List<MessageModel> get activeChatMessages => _activeChatMessages;
  StreamSubscription? _chatSubscription;

  void enterChat(String chatId) {
    _activeChatMessages = [];
    _chatSubscription?.cancel();
    _chatSubscription = _service.getPrivateMessages(chatId).listen((message) {
      _activeChatMessages.add(message);
      notifyListeners();
    });
  }

  void leaveChat() {
    _chatSubscription?.cancel();
    _activeChatMessages = [];
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (content.trim().isEmpty) return;

    final message = MessageModel(
      id: DateTime.now().toString(),
      senderHandle: 'Me',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    );
    _activeChatMessages.add(message);
    notifyListeners();

    try {
      await _service.sendPrivateMessage(chatId, content);
    } catch (e) {
      // Handle error (e.g. mark message as failed)
      debugPrint('Error sending message: $e');
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
