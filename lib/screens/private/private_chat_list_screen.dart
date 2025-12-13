import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/private_chat_provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrivateChatProvider>().loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================
  // ADD FRIEND ACTION
  // =========================
  void _showAddFriendDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(
          child: Text('Add Friend Dialog Here', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivateChatProvider>();

    return Scaffold(
      backgroundColor: Colors.white,

      // =========================
      // APP BAR
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Private Chats',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5), // Light grey background
              borderRadius: BorderRadius.circular(32),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelColor: Colors.grey[600],
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              tabs: const [
                Tab(text: 'Chats'),
                Tab(text: 'Received'),
                Tab(text: 'Sent'),
              ],
            ),
          ),
        ),
      ),

      // =========================
      // BODY
      // =========================
      body: TabBarView(
        controller: _tabController,
        children: [
          provider.chats.isEmpty
              ? _emptyState('No chats yet')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.chats.length,
                  itemBuilder: (_, i) {
                    final chat = provider.chats[i];
                    return _ChatTile(
                      title: chat.otherUserHandle,
                      subtitle: chat.lastMessage,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatDetailScreen(chat: chat),
                          ),
                        );
                      },
                    );
                  },
                ),
          _emptyState('No received requests'),
          _emptyState('No sent requests'),
        ],
      ),

      // =========================
      // CENTER DOCKED FAB
      // =========================
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Lift above Home Nav Bar
        child: FloatingActionButton(
          onPressed: _showAddFriendDialog,
          backgroundColor: Colors.black,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // =========================
  // UI HELPERS
  // =========================
  Widget _emptyState(String text) {
    return Center(
      child: Text(text, style: TextStyle(color: Colors.grey[400])),
    );
  }
}

// =========================
// CHAT TILE
// =========================
class _ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ChatTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(title[0].toUpperCase()),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
