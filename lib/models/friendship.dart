class Friendship {
  final String id;
  final String user1Id;
  final String user2Id;
  final String status; // pending, accepted, rejected
  final String requesterId;
  final DateTime createdAt;

  Friendship({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.requesterId,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      status: json['status'] as String,
      requesterId: json['requester_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool isPending() => status == 'pending';
  bool isAccepted() => status == 'accepted';
  bool isRejected() => status == 'rejected';

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  bool isRequester(String userId) => requesterId == userId;
}

class UserBlock {
  final String id;
  final String blockerId;
  final String blockedId;
  final String? reason;
  final DateTime createdAt;

  UserBlock({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    this.reason,
    required this.createdAt,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) {
    return UserBlock(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedId: json['blocked_id'] as String,
      reason: json['reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class UserReport {
  final String id;
  final String reporterId;
  final String reportedId;
  final String reason;
  final String? description;
  final String status; // pending, reviewed, resolved
  final DateTime createdAt;

  UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reason,
    this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      reportedId: json['reported_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
