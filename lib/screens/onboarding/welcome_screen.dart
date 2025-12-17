import 'package:flutter/material.dart';
import 'phone_input_screen.dart';
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ PUTIH
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'forum ',
                  style: TextStyle(
                    color: Color(0xFF2F80ED),
                    fontSize: 25,
                  ),
                ),
                Text(
                  'AnonChat Local',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // Card
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    Image.asset(
                      'assets/images/image.png',
                      height: 400,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'Welcome to AnonChat\nLocal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F80ED),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Connect with people nearby, anonymously.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 28),

                // Sign Up Button
SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PhoneInputScreen( phoneNumber: ''), // kosongkan nomor telepon
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2F80ED),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
    ),
    child: const Text(
      'Sign Up',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
),

const SizedBox(height: 4),

// Log In
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PhoneInputScreen(phoneNumber: ''),
      ),
    );
  },
  child: const Text(
    'Log In',
    style: TextStyle(
      color: Color(0xFF2F80ED),
      fontSize: 14,
    ),
  ),
),

const SizedBox(height: 12),

const Text(
  'Terms of Service & Privacy Policy',
  style: TextStyle(
    fontSize: 12,
    color: Colors.grey,
  ),
),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
