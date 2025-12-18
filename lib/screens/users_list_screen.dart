import 'package:flutter/material.dart';
import '../models/chat_user.dart';
import '../services/user_service.dart';
import 'supabase_chat_screen.dart';
import 'profile_edit_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserService _userService = UserService();
  List<ChatUser> _users = [];
  bool _isLoading = true;
  String? _currentUserId;
  ChatUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      _currentUser = await _userService.getCurrentUser();
      _currentUserId = _currentUser?.id;

      final users = await _userService.getAllUsers(
        excludeUserId: _currentUserId,
      );

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openChat(ChatUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupabaseChatScreen(otherUser: user),
      ),
    );
  }

  Future<void> _openProfileEdit() async {
    if (_currentUser == null) return;

    final updatedUser = await Navigator.push<ChatUser>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(currentUser: _currentUser!),
      ),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User to Chat'),
        actions: [
          IconButton(
            onPressed: _openProfileEdit,
            icon: const Icon(Icons.person),
            tooltip: 'Edit Profil',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? const Center(
                  child: Text('No users found. Wait for others to join!'),
                )
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl != null
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                          child: user.avatarUrl == null
                              ? Text(user.displayName[0].toUpperCase())
                              : null,
                        ),
                        title: Text(user.displayName),
                        subtitle: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                color: user.isOnline
                                    ? Colors.green
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chat_bubble_outline),
                        onTap: () => _openChat(user),
                      );
                    },
                  ),
                ),
    );
  }
}
