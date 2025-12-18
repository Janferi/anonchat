import 'package:flutter/material.dart';

class PrivacyDataScreen extends StatelessWidget {
  const PrivacyDataScreen({super.key});

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
          'Privacy & Data',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'How We Protect Your Privacy',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your privacy and safety are our top priorities. Here\'s a transparent overview of how we handle your data to ensure an anonymous and secure experience.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Privacy Cards
          _buildPrivacyCard(
            icon: Icons.location_on_outlined,
            title: 'How We Use Your Location',
            description:
                'Your location is only used to connect you with others nearby. It is never shared, stored long-term, or linked to your personal identity.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildPrivacyCard(
            icon: Icons.message_outlined,
            title: 'Temporary Message Storage',
            description:
                'Messages are stored temporarily for delivery and then permanently deleted from our servers after a short, defined period.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildPrivacyCard(
            icon: Icons.phone_outlined,
            title: 'Emergency Contact Use',
            description:
                'Your phone number is requested only for emergency purposes and is securely encrypted. It is never used for tracking or advertising.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildPrivacyCard(
            icon: Icons.shield_outlined,
            title: 'Data Encryption',
            description:
                'All your data is encrypted both in transit and at rest. We use industry-standard encryption to protect your information.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          _buildPrivacyCard(
            icon: Icons.no_accounts_outlined,
            title: 'Anonymous by Default',
            description:
                'We don\'t require personal information to use our app. Your username and avatar are optional, and you can change them anytime.',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
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
