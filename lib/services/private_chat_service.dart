import 'dart:async';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../models/friend_request_model.dart';
import '../models/private_chat_model.dart';
import '../models/message_model.dart';
import 'block_service.dart';

class PrivateChatService {
  final BlockService _blockService = BlockService();

  // E2EE Simulation
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  late final encrypt.Encrypter _encrypter;

  PrivateChatService() {
    // In real app, keys are exchanged via Diffie-Hellman or similar
    _key = encrypt.Key.fromUtf8('PrivateChatSecureKey32Chars!!!!');
    _iv = encrypt.IV.fromLength(16);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

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

  final List<FriendRequestModel> _mockSentRequests = [
    FriendRequestModel(
      id: 'sent_req1',
      fromUserHandle: 'Me',
      fromUserId: 'my_id',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      status: RequestStatus.pending,
    ),
  ];

  Future<List<FriendRequestModel>> getFriendRequests() async {
    await Future.delayed(const Duration(seconds: 1));

    // Filter blocked users
    final blockedUsers = await _blockService.getBlockedUsers();

    return _mockRequests
        .where(
          (r) =>
              r.status == RequestStatus.pending &&
              !blockedUsers.contains(r.fromUserId),
        )
        .toList();
  }

  Future<List<FriendRequestModel>> getSentFriendRequests() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockSentRequests;
  }

  Future<List<PrivateChatModel>> getPrivateChats() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockChats;
  }

  Future<bool> sendFriendRequest(String phoneNumber) async {
    await Future.delayed(const Duration(seconds: 2));
    if (phoneNumber == '08123456789') {
      return true;
    }
    throw Exception('User not found with this phone number');
  }

  Future<void> respondToRequest(String requestId, bool accept) async {
    await Future.delayed(const Duration(seconds: 1));
    final index = _mockRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
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

    // Yield initial history (Decrypted)
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!controller.isClosed) {
        try {
          // Simulating receiving encrypted data
          final originalText = 'Hey! Long time no see.';
          final encrypted = _encrypter.encrypt(originalText, iv: _iv);
          final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

          controller.add(
            MessageModel(
              id: 'msg_hist_1',
              senderHandle: 'Anon_Bestie',
              content: decrypted, // Decrypted locally
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isMe: false,
            ),
          );
        } catch (e) {
          // ignore: avoid_print
          print('Error loading message history: $e');
        }
      }
    });

    // Simulate incoming messages
    _chatTimers[chatId] = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      if (!controller.isClosed) {
        try {
          // Check block status
          // For simplicity reusing user3 for chat1
          final blockedUsers = await _blockService.getBlockedUsers();
          if (blockedUsers.contains('user3')) {
            // If blocked, don't show message
            return;
          }

          final originalText = 'Are you there?';
          final encrypted = _encrypter.encrypt(originalText, iv: _iv);
          final decrypted = _encrypter.decrypt(encrypted, iv: _iv);

          controller.add(
            MessageModel(
              id: DateTime.now().toString(),
              senderHandle: 'Anon_Bestie',
              content: decrypted,
              timestamp: DateTime.now(),
              isMe: false,
            ),
          );
        } catch (e) {
          // ignore: avoid_print
          print('Error receiving message: $e');
        }
      }
    });

    return controller.stream;
  }

  Future<void> sendPrivateMessage(String chatId, String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Simulate Encryption
    final encrypted = _encrypter.encrypt(content, iv: _iv);
    // In real app, POST /private/chat/{id}/message with encrypted.base64
    // ignore: avoid_print
    print('Sending Encrypted: ${encrypted.base64}');
  }

  Future<void> blockUser(String userId) async {
    await _blockService.blockUser(userId);
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
