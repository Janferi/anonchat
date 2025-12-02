import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/nearby_service.dart';

class NearbyProvider with ChangeNotifier {
  final NearbyService _nearbyService = NearbyService();
  List<ChatRoomModel> _rooms = [];
  final List<MessageModel> _messages = [];
  bool _isLoading = false;

  List<ChatRoomModel> get rooms => _rooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> fetchNearbyRooms(double lat, double lon) async {
    _isLoading = true;
    notifyListeners();
    try {
      _rooms = await _nearbyService.getNearbyRooms(lat, lon);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void joinRoom(String roomId) {
    _messages.clear();
    // Subscribe to messages
    _nearbyService.getMessages(roomId).listen((message) {
      _messages.add(message);
      notifyListeners();
    });
  }

  Future<void> sendMessage(String roomId, String content) async {
    final message = MessageModel(
      id: DateTime.now().toString(),
      senderHandle: 'Me',
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    );
    _messages.add(message);
    notifyListeners();
    await _nearbyService.sendMessage(roomId, content);
  }
}
