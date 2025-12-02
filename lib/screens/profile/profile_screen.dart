import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../onboarding/consent_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _displayNameController;
  late TextEditingController _handleController;
  late TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _handleController = TextEditingController(text: user?.anonHandle ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _handleController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    try {
      await context.read<AuthProvider>().updateProfile(
        displayName: _displayNameController.text.trim(),
        anonHandle: _handleController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  void _logout() {
    context.read<AuthProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ConsentScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(icon: const Icon(Icons.check), onPressed: _saveProfile),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    user.anonHandle.isNotEmpty
                        ? user.anonHandle[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 40, color: Colors.blue),
                  ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Change avatar coming soon'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),

            _buildTextField(
              label: 'Display Name',
              controller: _displayNameController,
              enabled: _isEditing,
              icon: Icons.person,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Username (Handle)',
              controller: _handleController,
              enabled: _isEditing,
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              label: 'Bio',
              controller: _bioController,
              enabled: _isEditing,
              icon: Icons.info_outline,
              maxLines: 3,
            ),

            const SizedBox(height: 40),

            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
    );
  }
}
