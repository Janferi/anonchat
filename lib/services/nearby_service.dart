import 'dart:async';
import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class NearbyService {
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

  Stream<MessageModel> getMessages(String roomId) async* {
    // Mock incoming messages
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      yield MessageModel(
        id: DateTime.now().toString(),
        senderHandle: 'Anon_User',
        content: 'Hello from nearby!',
        timestamp: DateTime.now(),
        isMe: false,
      );
    }
  }

  Future<void> sendMessage(String roomId, String content) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Send to backend
  }
}
