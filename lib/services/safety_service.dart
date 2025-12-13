import 'package:url_launcher/url_launcher.dart';

class SafetyService {
  // In-memory storage for reports: UserId -> List of Timestamps
  final Map<String, List<DateTime>> _userReportLogs = {};

  // Mock banned users list (simulating backend ban)
  final List<String> _bannedUsers = [];

  Future<void> makeNativeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> sendEmergencyPacket(double lat, double lon) async {
    // Mock sending emergency packet to backend
    await Future.delayed(const Duration(seconds: 2));
  }

  Future<void> reportUser(
    String userId,
    String reason,
    String description,
  ) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate API

    final now = DateTime.now();
    if (!_userReportLogs.containsKey(userId)) {
      _userReportLogs[userId] = [];
    }
    _userReportLogs[userId]!.add(now);

    // Prune old reports (> 1 day/5 mins for different checks)
    // We check for:
    // 1. Auto-ban: >= 3 reports in 5 minutes
    final recentReports = _userReportLogs[userId]!
        .where((t) => now.difference(t).inMinutes <= 5)
        .toList();

    if (recentReports.length >= 3) {
      _banUser(userId, 'Auto-ban: Too many reports in 5 minutes');
    }

    // 2. Escalation: > 10 reports in 24 hours
    final dailyReports = _userReportLogs[userId]!
        .where((t) => now.difference(t).inHours <= 24)
        .toList();

    if (dailyReports.length > 10) {
      // ignore: avoid_print
      print(
        'ESCALATION: User $userId flagged for human review (High report volume)',
      );
    }

    // Log violation locally/backend
    // ignore: avoid_print
    print('REPORT LOG: User $userId reported for $reason. Desc: $description');
  }

  void _banUser(String userId, String reason) {
    if (!_bannedUsers.contains(userId)) {
      _bannedUsers.add(userId);
      // ignore: avoid_print
      print('USER BANNED: $userId. Reason: $reason');
    }
  }

  bool isUserBanned(String userId) {
    return _bannedUsers.contains(userId);
  }
}
