import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Consent',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Shield Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    size: 60,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              /// Title
              const Text(
                'Your Privacy is Our\nPriority',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 16),

              /// Subtitle
              const Text(
                'To help you connect with people nearby, we need your consent to access certain data. We are committed to protecting your anonymity and ensuring your data is handled securely.',
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6),
              ),

              const SizedBox(height: 32),

              /// Location Access
              _buildFeatureItem(
                icon: Icons.location_on,
                title: 'Location Access',
                description:
                    'We use your location to find and connect you to local chat rooms. Your precise location is never shared with other users.',
              ),

              const SizedBox(height: 24),

              /// Data Usage
              _buildFeatureItem(
                icon: Icons.chat_bubble_outline,
                title: 'Data Usage',
                description:
                    'Your anonymous chat data is used to improve the app experience. We do not analyze personal conversations.',
              ),

              const SizedBox(height: 24),

              /// Anonymity Guaranteed
              _buildFeatureItem(
                icon: Icons.phone_disabled,
                title: 'Anonymity Guaranteed',
                description:
                    'Your personal identity is never linked to your profile or chats, ensuring you can connect with others safely and privately.',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: Colors.blue),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
