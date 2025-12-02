enum RequestStatus { pending, accepted, rejected }

class FriendRequestModel {
  final String id;
  final String fromUserHandle;
  final String fromUserId;
  final DateTime timestamp;
  final RequestStatus status;

  FriendRequestModel({
    required this.id,
    required this.fromUserHandle,
    required this.fromUserId,
    required this.timestamp,
    required this.status,
  });
}
