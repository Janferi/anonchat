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
  Timer? _dummyMessageTimer;
  String? _currentRoomId;

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
    _currentRoomId = roomId;

    // Notify listeners immediately so member count updates
    notifyListeners();

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

    // Start dummy messages for demo purposes
    _startDummyMessages(roomId);
  }

  void leaveRoom() {
    _roomSubscription?.cancel();
    _cleanupTimer?.cancel();
    _dummyMessageTimer?.cancel();
    _roomSubscription = null;
    _cleanupTimer = null;
    _dummyMessageTimer = null;
    _currentRoomId = null;
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

  // Mock member count for demo purposes
  int get memberCount {
    if (_currentRoomId == null) return 0;
    // Generate random member count based on room name
    final roomName = _allRooms
        .firstWhere((r) => r.id == _currentRoomId, orElse: () => _allRooms.first)
        .name
        .toLowerCase();

    if (roomName.contains('coffee') || roomName.contains('shop')) {
      return 8;
    } else if (roomName.contains('park')) {
      return 12;
    } else if (roomName.contains('library')) {
      return 5;
    }
    return 3;
  }

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

  void _startDummyMessages(String roomId) {
    // Get room name to determine topic
    final room = _allRooms.firstWhere(
      (r) => r.id == roomId,
      orElse: () => _allRooms.first,
    );
    final roomName = room.name.toLowerCase();

    // Determine conversation topic and users based on room
    List<Map<String, String>> conversation;
    if (roomName.contains('coffee') || roomName.contains('shop')) {
      conversation = _getCoffeeShopConversation();
    } else if (roomName.contains('park')) {
      conversation = _getParkConversation();
    } else if (roomName.contains('library')) {
      conversation = _getLibraryConversation();
    } else {
      conversation = _getGeneralConversation();
    }

    int messageIndex = 0;

    // Send messages every 5-10 seconds
    _dummyMessageTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (messageIndex < conversation.length) {
        final msgData = conversation[messageIndex];
        final message = MessageModel(
          id: DateTime.now().toString() + messageIndex.toString(),
          senderHandle: msgData['sender']!,
          content: msgData['content']!,
          timestamp: DateTime.now(),
          isMe: false,
        );
        _messages.add(message);
        notifyListeners();
        messageIndex++;
      } else {
        // Loop back to beginning
        messageIndex = 0;
      }
    });
  }

  List<Map<String, String>> _getCoffeeShopConversation() {
    return [
      {
        'sender': 'User_A823',
        'content': 'Anyone know of a good coffee shop that\'s open late around here?'
      },
      {
        'sender': 'User_C789',
        'content': 'Yeah, The Daily Grind on 4th Street is open until 10 PM. Great espresso!'
      },
      {
        'sender': 'User_B456',
        'content': 'Second that! Their pastries are amazing too.'
      },
      {
        'sender': 'User_D921',
        'content': 'Has anyone tried their new seasonal latte? Worth it?'
      },
      {
        'sender': 'User_A823',
        'content': 'I tried it yesterday! The pumpkin spice is really good, not too sweet.'
      },
      {
        'sender': 'User_E234',
        'content': 'Do they have good WiFi? Looking for a place to work from.'
      },
      {
        'sender': 'User_C789',
        'content': 'WiFi is solid, and plenty of outlets. Gets busy around lunch though.'
      },
    ];
  }

  List<Map<String, String>> _getParkConversation() {
    return [
      {
        'sender': 'User_J128',
        'content': 'Beautiful day at the park today! Anyone else here?'
      },
      {
        'sender': 'User_K456',
        'content': 'Just finished a run around the trail. The weather is perfect!'
      },
      {
        'sender': 'User_L789',
        'content': 'Are the basketball courts free? Thinking of shooting some hoops.'
      },
      {
        'sender': 'User_M234',
        'content': 'Yeah they\'re open! I was there 10 mins ago, only one court occupied.'
      },
      {
        'sender': 'User_J128',
        'content': 'Anyone want to join for a picnic later? Got extra sandwiches.'
      },
      {
        'sender': 'User_N567',
        'content': 'The food trucks are here today! Tacos and burgers.'
      },
      {
        'sender': 'User_K456',
        'content': 'Perfect! I\'m starving after that run. Where are they parked?'
      },
      {
        'sender': 'User_N567',
        'content': 'Near the main entrance, can\'t miss them!'
      },
    ];
  }

  List<Map<String, String>> _getLibraryConversation() {
    return [
      {
        'sender': 'User_P892',
        'content': 'Looking for a quiet study spot. How crowded is it right now?'
      },
      {
        'sender': 'User_Q345',
        'content': 'Third floor is pretty empty. Found a good corner desk.'
      },
      {
        'sender': 'User_R678',
        'content': 'Does anyone know if the study rooms are bookable today?'
      },
      {
        'sender': 'User_S123',
        'content': 'Yeah, use the library app. Room 304 is free until 5 PM.'
      },
      {
        'sender': 'User_P892',
        'content': 'Thanks! Need to prep for finals. So stressful.'
      },
      {
        'sender': 'User_T456',
        'content': 'Same here. Anyone studying for Biology 201?'
      },
      {
        'sender': 'User_Q345',
        'content': 'I am! Maybe we could form a study group?'
      },
    ];
  }

  List<Map<String, String>> _getGeneralConversation() {
    return [
      {
        'sender': 'User_X111',
        'content': 'Hey everyone! First time using this app.'
      },
      {
        'sender': 'User_Y222',
        'content': 'Welcome! It\'s pretty cool, you can chat with people nearby.'
      },
      {
        'sender': 'User_Z333',
        'content': 'Anyone know what\'s happening at the plaza tonight?'
      },
      {
        'sender': 'User_X111',
        'content': 'I think there\'s a live music event at 7 PM.'
      },
      {
        'sender': 'User_Y222',
        'content': 'Oh nice! What kind of music?'
      },
    ];
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
