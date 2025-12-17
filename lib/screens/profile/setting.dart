import 'package:flutter/material.dart';

class DataPermissionsPage extends StatelessWidget {
  const DataPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Privacy & Data',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// Title
          const Text(
            'How We Protect Your Privacy',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          /// Description
          Text(
            'Your privacy and safety are our top priorities. '
            'Here’s a transparent overview of how we handle your data '
            'to ensure an anonymous and secure experience.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          /// Cards
          _privacyCard(
            icon: Icons.location_on,
            title: 'How We Use Your Location',
            description:
                'Your location is only used to connect you with others nearby. '
                'It is never shared, stored long-term, or linked to your personal identity.',
          ),
          const SizedBox(height: 16),

          _privacyCard(
            icon: Icons.access_time,
            title: 'Temporary Message Storage',
            description:
                'Messages are stored temporarily for delivery and then permanently '
                'deleted from our servers after a short, defined period.',
          ),
          const SizedBox(height: 16),

          _privacyCard(
            icon: Icons.shield,
            title: 'Emergency Contact Use',
            description:
                'Your phone number is requested only for emergency purposes '
                'and is securely encrypted. It is never used for tracking or advertising.',
          ),
        ],
      ),
    );
  }

  Widget _privacyCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
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
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
