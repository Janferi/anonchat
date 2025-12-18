class ChatUser {
  final String id;
  final String phoneNumber;
  final String? deviceId;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;

  ChatUser({
    required this.id,
    required this.phoneNumber,
    this.deviceId,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
  });

  // Display name dengan fallback ke nomor telepon
  String get displayName => username ?? phoneNumber;

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      deviceId: json['device_id'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeen: DateTime.parse(json['last_seen'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'device_id': deviceId,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChatUser copyWith({
    String? id,
    String? phoneNumber,
    String? deviceId,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return ChatUser(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      deviceId: deviceId ?? this.deviceId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
