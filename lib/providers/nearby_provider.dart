import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/nearby_service.dart';

class NearbyProvider with ChangeNotifier {
  final NearbyService _nearbyService = NearbyService();
  List<ChatRoomModel> _rooms = [];
  List<ChatRoomModel> _allRooms = [];
  final List<MessageModel> _messages = [];
  bool _isLoading = false;
  double _radius = 500; // Default 500m
  StreamSubscription? _roomSubscription;

  List<ChatRoomModel> get rooms => _rooms;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  double get radius => _radius;

  void setRadius(double newRadius) {
    _radius = newRadius;
    _filterRooms();
    notifyListeners();
  }

  Future<void> fetchNearbyRooms(double lat, double lon) async {
    _isLoading = true;
    notifyListeners();
    try {
      _allRooms = await _nearbyService.getNearbyRooms(lat, lon);
      _filterRooms();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _filterRooms() {
    _rooms = _allRooms.where((room) => room.distance <= _radius).toList();
  }

  void joinRoom(String roomId) {
    leaveRoom();
    _messages.clear();
    // Subscribe to messages
    _roomSubscription = _nearbyService.getMessages(roomId).listen((message) {
      _messages.add(message);
      notifyListeners();
    });
  }

  void leaveRoom() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
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

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _nearbyService.dispose();
    super.dispose();
  }
}
