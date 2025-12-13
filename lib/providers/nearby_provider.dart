import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import '../services/nearby_service.dart';
import '../services/location_service.dart';

class NearbyProvider with ChangeNotifier {
  final NearbyService _nearbyService = NearbyService();
  final LocationService _locationService =
      LocationService(); // Inject LocationService

  List<ChatRoomModel> _rooms = [];
  List<ChatRoomModel> _allRooms = [];
  final List<MessageModel> _messages = [];

  bool _isLoading = false;
  double _radius = 500; // Default 500m
  LatLng? _currentPosition;
  StreamSubscription? _roomSubscription;
  Timer? _cleanupTimer;

  List<ChatRoomModel> get rooms => _rooms;
  bool get isLoading => _isLoading;
  double get radius => _radius;
  LatLng? get currentPosition => _currentPosition;

  void setRadius(double newRadius) {
    _radius = newRadius;
    _filterRooms();
    notifyListeners();
  }

  Future<void> initializeLocation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        _currentPosition = LatLng(position.latitude, position.longitude);
        await fetchNearbyRooms(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      }
    } catch (e) {
      debugPrint("Error initializing location: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNearbyRooms(double lat, double lon) async {
    // We don't set loading here to avoid full screen flicker if just refreshing
    try {
      _allRooms = await _nearbyService.getNearbyRooms(lat, lon);
      _filterRooms();
    } catch (e) {
      debugPrint("Error fetching rooms: $e");
    }
    notifyListeners();
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

    // Cleanup old messages every minute
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      _messages.removeWhere(
        (msg) => now.difference(msg.timestamp).inMinutes > 15,
      );
      notifyListeners();
    });
  }

  void leaveRoom() {
    _roomSubscription?.cancel();
    _cleanupTimer?.cancel();
    _roomSubscription = null;
    _cleanupTimer = null;
  }

  Future<void> createRoom(String name) async {
    if (_currentPosition == null) return;

    try {
      await _nearbyService.createRoom(
        name,
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      // Refresh list
      await fetchNearbyRooms(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    } catch (e) {
      debugPrint("Error creating room: $e");
      rethrow;
    }
  }

  // Mock member count for now, or fetch from active room logic
  int get memberCount => 0;

  Future<void> sendMessageOptimistic({
    required String roomId,
    required String content,
    required String senderHandle,
  }) async {
    final message = MessageModel(
      id: DateTime.now().toString(),
      senderHandle: senderHandle,
      content: content,
      timestamp: DateTime.now(),
      isMe: true,
    );
    _messages.add(message);
    notifyListeners();
    await _nearbyService.sendMessage(roomId, content);
  }

  // Legacy method kept if needed or redirected
  Future<void> sendMessage(
    String roomId,
    String content,
    String senderHandle,
  ) async {
    return sendMessageOptimistic(
      roomId: roomId,
      content: content,
      senderHandle: senderHandle,
    );
  }

  DateTime? _lastIceBreakerTime;

  bool sendIceBreaker(String roomId) {
    final now = DateTime.now();
    if (_lastIceBreakerTime != null) {
      final difference = now.difference(_lastIceBreakerTime!);
      if (difference.inSeconds < 30) {
        return false; // Cooldown active
      }
    }

    _lastIceBreakerTime = now;
    final topic = _nearbyService.getRandomTopic();
    final message = MessageModel(
      id: DateTime.now().toString(),
      senderHandle: '🤖 TopicBot',
      content: topic,
      timestamp: DateTime.now(),
      isMe: false, // Bot is not "Me"
    );
    _messages.add(message);
    notifyListeners();
    return true; // Sent successfully
  }

  List<String> _blockedUsers = [];

  void blockUser(String userHandle) {
    if (!_blockedUsers.contains(userHandle)) {
      _blockedUsers.add(userHandle);
      notifyListeners();
    }
  }

  List<MessageModel> get messages => _messages
      .where((msg) => !_blockedUsers.contains(msg.senderHandle))
      .toList();

  @override
  void dispose() {
    leaveRoom();
    _nearbyService.dispose();
    super.dispose();
  }
}
