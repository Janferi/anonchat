class NearbyGroup {
  final String id;
  final String name;
  final String? description;
  final String creatorId;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final bool isActive;
  final int maxMembers;
  final DateTime createdAt;

  NearbyGroup({
    required this.id,
    required this.name,
    this.description,
    required this.creatorId,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 1000,
    this.isActive = true,
    this.maxMembers = 50,
    required this.createdAt,
  });

  factory NearbyGroup.fromJson(Map<String, dynamic> json) {
    return NearbyGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      creatorId: json['creator_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radius_meters'] as int? ?? 1000,
      isActive: json['is_active'] as bool? ?? true,
      maxMembers: json['max_members'] as int? ?? 50,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'creator_id': creatorId,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'is_active': isActive,
      'max_members': maxMembers,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class GroupMessage {
  final String id;
  final String groupId;
  final String senderId;
  final String messageText;
  final String messageType;
  final bool isDeleted;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.messageText,
    this.messageType = 'text',
    this.isDeleted = false,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      messageText: json['message_text'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
