import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Model untuk Safety Call
class SafetyCall {
  final String id;
  final String contactName;
  final String contactNumber;
  final DateTime timestamp;
  final String status; // 'completed', 'missed', 'emergency'
  final int duration; // in seconds

  SafetyCall({
    required this.id,
    required this.contactName,
    required this.contactNumber,
    required this.timestamp,
    required this.status,
    required this.duration,
  });
}

class SafetyCallHistoryScreen extends StatefulWidget {
  const SafetyCallHistoryScreen({super.key});

  @override
  State<SafetyCallHistoryScreen> createState() => _SafetyCallHistoryScreenState();
}

class _SafetyCallHistoryScreenState extends State<SafetyCallHistoryScreen> {
  bool _isLoading = true;
  List<SafetyCall> _callHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);

    // TODO: Implement actual API call to fetch safety call history from Supabase
    // For now, using dummy data
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _callHistory = [
        // Dummy data - replace with actual API call
        SafetyCall(
          id: '1',
          contactName: 'Mom',
          contactNumber: '+6281234567890',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: 'completed',
          duration: 45,
        ),
        SafetyCall(
          id: '2',
          contactName: 'Emergency Contact',
          contactNumber: '+6287654321098',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          status: 'emergency',
          duration: 120,
        ),
      ];
      _isLoading = false;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'missed':
        return Colors.orange;
      case 'emergency':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'missed':
        return Icons.phone_missed;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.phone;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'missed':
        return 'Missed';
      case 'emergency':
        return 'Emergency';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Safety Call History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Call History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your safety call history will appear here',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCallHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _callHistory.length,
                    itemBuilder: (context, index) {
                      final call = _callHistory[index];
                      final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(call.status).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getStatusIcon(call.status),
                                    color: _getStatusColor(call.status),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        call.contactName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        call.contactNumber,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(call.status).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getStatusText(call.status),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(call.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: Colors.grey[200]),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormat.format(call.timestamp),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDuration(call.duration),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
