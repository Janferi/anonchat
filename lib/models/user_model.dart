class UserModel {
  final String id;
  final String anonHandle;
  final bool consentGiven;
  final DateTime lastActivity;

  UserModel({
    required this.id,
    required this.anonHandle,
    required this.consentGiven,
    required this.lastActivity,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      anonHandle: json['anon_handle'],
      consentGiven: json['consent_flag'] ?? false,
      lastActivity: DateTime.parse(json['last_activity_ts']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'anon_handle': anonHandle,
      'consent_flag': consentGiven,
      'last_activity_ts': lastActivity.toIso8601String(),
    };
  }
}
