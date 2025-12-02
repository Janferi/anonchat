class UserModel {
  final String id;
  final String anonHandle;
  final String displayName;
  final String bio;
  final bool consentGiven;
  final DateTime lastActivity;

  UserModel({
    required this.id,
    required this.anonHandle,
    this.displayName = '',
    this.bio = '',
    required this.consentGiven,
    required this.lastActivity,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      anonHandle: json['anon_handle'],
      displayName: json['display_name'] ?? '',
      bio: json['bio'] ?? '',
      consentGiven: json['consent_flag'] ?? false,
      lastActivity: DateTime.parse(json['last_activity_ts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anon_handle': anonHandle,
      'display_name': displayName,
      'bio': bio,
      'consent_flag': consentGiven,
      'last_activity_ts': lastActivity.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? anonHandle,
    String? displayName,
    String? bio,
    bool? consentGiven,
    DateTime? lastActivity,
  }) {
    return UserModel(
      id: id,
      anonHandle: anonHandle ?? this.anonHandle,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      consentGiven: consentGiven ?? this.consentGiven,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }
}
