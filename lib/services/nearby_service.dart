import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class NearbyService {
  // Keep track of active streams to simulate real-time updates
  final Map<String, StreamController<MessageModel>> _roomControllers = {};
  final Map<String, Timer> _roomTimers = {};

  final List<ChatRoomModel> _userRooms = [];

  Future<List<ChatRoomModel>> getNearbyRooms(double lat, double lon) async {
    await Future.delayed(const Duration(seconds: 1));

    // System Rooms (Mock)
    final systemRooms = [
      ChatRoomModel(
        id: 'sys_1',
        name: 'Central Park',
        memberCount: 12,
        distance: 150, // This should be calculated dynamically in real app
        lat: lat + 0.001,
        lon: lon + 0.001,
        isSystem: true,
      ),
      ChatRoomModel(
        id: 'sys_2',
        name: 'Coffee Shop',
        memberCount: 5,
        distance: 50,
        lat: lat - 0.0005,
        lon: lon + 0.0005,
        isSystem: true,
      ),
      ChatRoomModel(
        id: 'sys_3',
        name: 'Library',
        memberCount: 25,
        distance: 300,
        lat: lat + 0.002,
        lon: lon - 0.001,
        isSystem: true,
      ),
    ];

    return [...systemRooms, ..._userRooms];
  }

  Future<ChatRoomModel> createRoom(String name, double lat, double lon) async {
    await Future.delayed(const Duration(seconds: 1));
    final newRoom = ChatRoomModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      memberCount: 1, // Creator
      distance: 0, // 0 because user is at location
      lat: lat,
      lon: lon,
      isSystem: false,
    );
    _userRooms.add(newRoom);
    return newRoom;
  }

  Stream<MessageModel> getMessages(String roomId) {
    // Close existing stream for this room if any (to reset)
    _disposeRoom(roomId);

    final controller = StreamController<MessageModel>.broadcast(
      onCancel: () {
        // Optional: clean up when no listeners
      },
    );
    _roomControllers[roomId] = controller;

    // No more automatic messages - we use dummy messages from NearbyProvider instead

    return controller.stream;
  }

  Future<void> sendMessage(String roomId, String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would go to the server.
    // For mock, we don't need to echo it back because the provider adds it locally.
  }

  static const List<String> _topics = [
    "Apa makanan terenak di sekitar sini?",
    "Ada cerita horor lokal yang terkenal gak?",
    "Tempat nongkrong paling asik di mana?",
    "Siapa yang lagi jomblo di sini? 🤣",
    "Lagu apa yang lagi sering kalian dengerin?",
    "Kalo bisa punya kekuatan super, mau pilih apa?",
    "Ada rekomendasi film bagus buat weekend?",
    "Hal paling konyol yang pernah kalian alami apa?",
  ];

  String getRandomTopic() {
    return _topics[DateTime.now().millisecond % _topics.length];
  }

  void _disposeRoom(String roomId) {
    _roomTimers[roomId]?.cancel();
    _roomTimers.remove(roomId);
    _roomControllers[roomId]?.close();
    _roomControllers.remove(roomId);
  }

  void dispose() {
    for (var timer in _roomTimers.values) {
      timer.cancel();
    }
    for (var controller in _roomControllers.values) {
      controller.close();
    }
    _roomTimers.clear();
    _roomControllers.clear();
  }
}
