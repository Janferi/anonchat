import 'dart:async';
import '../models/friend_request_model.dart';
import '../models/private_chat_model.dart';
import '../models/message_model.dart';

class PrivateChatService {
  // Mock data
  final List<FriendRequestModel> _mockRequests = [
    FriendRequestModel(
      id: 'req1',
      fromUserHandle: 'Anon_Stalker',
      fromUserId: 'user2',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      status: RequestStatus.pending,
    ),
  ];

  final List<PrivateChatModel> _mockChats = [
    PrivateChatModel(
      id: 'chat1',
      otherUserHandle: 'Anon_Bestie',
      otherUserId: 'user3',
      lastMessage: 'See you tomorrow!',
      lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  Future<List<FriendRequestModel>> getFriendRequests() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockRequests
        .where((r) => r.status == RequestStatus.pending)
        .toList();
  }

  Future<List<PrivateChatModel>> getPrivateChats() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockChats;
  }

  Future<bool> sendFriendRequest(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    // Simulate finding user and sending request
    if (phoneNumber == '08123456789') {
      return true; // User found
    }
    throw Exception('User not found with this phone number');
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      // In real app, update backend
      // For mock, we just remove it from pending list effectively
      // If accepted, we would add to _mockChats
      if (accept) {
        _mockChats.add(
          PrivateChatModel(
            id: 'new_chat_${DateTime.now().millisecondsSinceEpoch}',
            otherUserHandle: _mockRequests[index].fromUserHandle,
            otherUserId: _mockRequests[index].fromUserId,
            lastMessage: 'New connection established',
            lastMessageTime: DateTime.now(),
          ),
        );
      }
      _mockRequests.removeAt(index);
    }
  }

  final Map<String, StreamController<MessageModel>> _chatControllers = {};
  final Map<String, Timer> _chatTimers = {};

  Stream<MessageModel> getPrivateMessages(String chatId) {
    _disposeChat(chatId);

    final controller = StreamController<MessageModel>.broadcast();
    _chatControllers[chatId] = controller;

    // Yield initial history
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!controller.isClosed) {
        controller.add(
          MessageModel(
            id: 'msg_hist_1',
            senderHandle: 'Anon_Bestie',
            content: 'Hey! Long time no see.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isMe: false,
          ),
        );
      }
    });

    // Simulate incoming messages
    _chatTimers[chatId] = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!controller.isClosed) {
        controller.add(
          MessageModel(
            id: DateTime.now().toString(),
            senderHandle: 'Anon_Bestie',
            content: 'Are you there?',
            timestamp: DateTime.now(),
            isMe: false,
          ),
        );
      }
    });

    return controller.stream;
  }

  Future<void> sendPrivateMessage(String chatId, String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In real app, POST /private/chat/{id}/message
  }

  void _disposeChat(String chatId) {
    _chatTimers[chatId]?.cancel();
    _chatTimers.remove(chatId);
    _chatControllers[chatId]?.close();
    _chatControllers.remove(chatId);
  }

  void dispose() {
    for (var timer in _chatTimers.values) {
      timer.cancel();
    }
    for (var controller in _chatControllers.values) {
      controller.close();
    }
    _chatTimers.clear();
    _chatControllers.clear();
  }
}
