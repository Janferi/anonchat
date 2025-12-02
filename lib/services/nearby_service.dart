import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class NearbyService {
  // Keep track of active streams to simulate real-time updates
  final Map<String, StreamController<MessageModel>> _roomControllers = {};
  final Map<String, Timer> _roomTimers = {};

  Future<List<ChatRoomModel>> getNearbyRooms(double lat, double lon) async {
    await Future.delayed(const Duration(seconds: 1));
    // Mock rooms around the user's location
    return [
      ChatRoomModel(
        id: '1',
        name: 'Central Park',
        memberCount: 12,
        distance: 150,
        lat: lat + 0.001,
        lon: lon + 0.001,
      ),
      ChatRoomModel(
        id: '2',
        name: 'Coffee Shop',
        memberCount: 5,
        distance: 50,
        lat: lat - 0.0005,
        lon: lon + 0.0005,
      ),
      ChatRoomModel(
        id: '3',
        name: 'Library',
        memberCount: 25,
        distance: 300,
        lat: lat + 0.002,
        lon: lon - 0.001,
      ),
    ];
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

    // Simulate incoming messages
    _roomTimers[roomId] = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!controller.isClosed) {
        controller.add(
          MessageModel(
            id: DateTime.now().toString(),
            senderHandle: 'Anon_User',
            content: 'Hello from nearby! Anyone here?',
            timestamp: DateTime.now(),
            isMe: false,
          ),
        );
      }
    });

    return controller.stream;
  }

  Future<void> sendMessage(String roomId, String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In a real app, this would go to the server.
    // For mock, we don't need to echo it back because the provider adds it locally.
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
