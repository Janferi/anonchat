import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'otp_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Consent',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      // ===== BODY =====
      body: SafeArea(
        child: Column(
          children: [
            // ===== CONTENT (SCROLL) =====
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Shield Icon
                    Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F80ED).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          size: 42,
                          color: Color(0xFF2F80ED),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'Your Privacy is Our\nPriority',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'To help you connect with people nearby, we need your consent to access certain data. We are committed to protecting your anonymity and ensuring your data is handled securely.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF828282),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 28),

                    _featureItem(
                      icon: Icons.location_on_outlined,
                      title: 'Location Access',
                      description:
                          'We use your location to find and connect you to local chat rooms. Your precise location is never shared with other users.',
                    ),

                    const SizedBox(height: 20),

                    _featureItem(
                      icon: Icons.chat_bubble_outline,
                      title: 'Data Usage',
                      description:
                          'Your anonymous chat data is used to improve the app experience. We do not analyze personal conversations.',
                    ),

                    const SizedBox(height: 20),

                    _featureItem(
                      icon: Icons.visibility_off_outlined,
                      title: 'Anonymity Guaranteed',
                      description:
                          'Your personal identity is never linked to your profile or chats, ensuring you can connect with others safely and privately.',
                    ),

                    const SizedBox(height: 24),

                    // Footer text
                    Center(
                      child: Text(
                        'By continuing, you agree to our Privacy Policy and\nTerms of Service.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== BOTTOM ACTION =====
            if (phoneNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );

                          try {
                            // KIRIM OTP DI SINI
                            await authProvider.requestOtp(phoneNumber);

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OtpScreen(phoneNumber: phoneNumber),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Failed to send OTP. Please try again.',
                                  ),
                                ),
                              );
                            }
                          }
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F80ED),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: const Text(
                          'Agree & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ===== FEATURE ITEM =====
  Widget _featureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2F80ED)),
        ),
        const SizedBox(width: 16),
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
                  color: Color(0xFF828282),
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
