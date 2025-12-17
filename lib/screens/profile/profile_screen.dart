import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/consent_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConsentScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account & Identity
          _section(
            title: 'Account & Identity',
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint, color: Colors.blue),
              ),
              title: const Text('Anonymous ID'),
              subtitle: Text(user?.anonHandle ?? 'anon-id-12345xyz'),
              trailing: TextButton(
                onPressed: null, // disabled
                child: const Text('Reset Identity'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy
          _section(
            title: 'Privacy',
            child: const Column(
              children: [
                _StaticTile(
                  icon: Icons.storage_outlined,
                  title: 'Data & Permissions',
                ),
                _Divider(),
                _StaticTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Settings',
                ),
                _Divider(),
                _StaticTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Consent & Privacy Policy',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Safety
          _section(
            title: 'Safety',
            child: const Column(
              children: [
                _StaticTile(icon: Icons.history, title: 'Safety Call History'),
                _Divider(),
                _StaticTile(icon: Icons.block_outlined, title: 'Blocked Users'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Logout
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _StaticTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _StaticTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: null, // disabled
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56);
  }
}
