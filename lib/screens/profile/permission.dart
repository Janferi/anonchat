import 'package:flutter/material.dart';

class DataPermissionsPage extends StatefulWidget {
  const DataPermissionsPage({super.key});

  @override
  State<DataPermissionsPage> createState() => _DataPermissionsPageState();
}

class _DataPermissionsPageState extends State<DataPermissionsPage> {
  bool pushNotification = true;
  bool emergencyContact = false;
  bool backgroundLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Data & Permissions',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _permissionCard(
            icon: Icons.location_on,
            title: 'Location Access',
            description:
                'Location is the core of our service, allowing you to find and connect with chats nearby.',
            trailing: TextButton(
              onPressed: () {},
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _permissionCard(
            icon: Icons.notifications,
            title: 'Push Notifications',
            description:
                'Get notified about new messages and important activity so you don’t miss out.',
            trailing: Switch(
              value: pushNotification,
              onChanged: (value) {
                setState(() {
                  pushNotification = value;
                });
              },
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 14),
          _permissionCard(
            icon: Icons.shield,
            title: 'Emergency-only contact data',
            description:
                'This data is encrypted and only used when the emergency button is activated.',
            trailing: Switch(
              value: emergencyContact,
              onChanged: (value) {
                setState(() {
                  emergencyContact = value;
                });
              },
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 14),
          _permissionCard(
            icon: Icons.my_location,
            title: 'Background location',
            description:
                'Improves your experience by keeping local chats updated, even when the app is not in use.',
            trailing: Switch(
              value: backgroundLocation,
              onChanged: (value) {
                setState(() {
                  backgroundLocation = value;
                });
              },
              activeColor: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _permissionCard({
    required IconData icon,
    required String title,
    required String description,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
