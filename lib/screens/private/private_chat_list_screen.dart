import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../models/friend_request_model.dart';
import 'private_chat_detail_screen.dart';

class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() => _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PrivateChatProvider>(context, listen: false).loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddFriendDialog() {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Friend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter phone number to send a friend request.'),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '08...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await Provider.of<PrivateChatProvider>(
                    context,
                    listen: false,
                  ).sendFriendRequest(phone);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request sent!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PrivateChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Chats Tab
                provider.chats.isEmpty
                    ? const Center(child: Text('No active chats yet.'))
                    : ListView.builder(
                        itemCount: provider.chats.length,
                        itemBuilder: (context, index) {
                          final chat = provider.chats[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(chat.otherUserHandle[0]),
                            ),
                            title: Text(chat.otherUserHandle),
                            subtitle: Text(chat.lastMessage),
                            trailing: Text(
                              '${chat.lastMessageTime.hour}:${chat.lastMessageTime.minute}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PrivateChatDetailScreen(chat: chat),
                                ),
                              );
                            },
                          );
                        },
                      ),

                // Requests Tab
                provider.requests.isEmpty
                    ? const Center(child: Text('No pending requests.'))
                    : ListView.builder(
                        itemCount: provider.requests.length,
                        itemBuilder: (context, index) {
                          final req = provider.requests[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person_add,
                                color: Colors.blue,
                              ),
                              title: Text(req.fromUserHandle),
                              subtitle: const Text('Wants to connect with you'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    onPressed: () {
                                      provider.respondToRequest(req.id, true);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      provider.respondToRequest(req.id, false);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
