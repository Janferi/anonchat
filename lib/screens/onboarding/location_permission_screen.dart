import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../home_screen.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isLoading = false;

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      _showMessage('Location permission was denied.');
      setState(() => _isLoading = false);
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage(
        'Location permission is permanently denied. Please enable it from settings.',
      );
      setState(() => _isLoading = false);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              /// Icon
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 56,
                  color: Color(0xFF2F80ED),
                ),
              ),

              const SizedBox(height: 36),

              /// Title
              const Text(
                'Enable Location to\nConnect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 14),

              /// Subtitle
              const Text(
                'AnonChat Local uses your location to find\n'
                'and connect you with anonymous users in\n'
                'your immediate area. Your exact position is\n'
                'never shared.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF828282),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 44),

              /// Allow Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    disabledBackgroundColor:
                        const Color(0xFF2F80ED).withOpacity(0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Allow Location',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              /// Not Now
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HomeScreen(),
                          ),
                        );
                      },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF828282),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
