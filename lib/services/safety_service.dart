import 'package:url_launcher/url_launcher.dart';

class SafetyService {
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
}
