import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/chat_user.dart';
import '../../models/chat_room.dart';
import '../../models/chat_message.dart';
import '../../services/chat_service.dart';
import 'private_chat_detail_screen.dart';
import 'package:intl/intl.dart';

class PrivateChatListScreen extends StatefulWidget {
  const PrivateChatListScreen({super.key});

  @override
  State<PrivateChatListScreen> createState() => _PrivateChatListScreenState();
}

class _PrivateChatListScreenState extends State<PrivateChatListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.userId != null) {
        context.read<PrivateChatProvider>().loadData(authProvider.userId!);
      }
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return const _AddFriendBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrivateChatProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Private Chats',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_outlined, color: Colors.black),
                tooltip: 'Add Friend',
                onPressed: _showAddFriendDialog,
              ),
              if (provider.friendRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${provider.friendRequests.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.black,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelColor: Colors.grey[600],
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              tabs: [
                const Tab(text: 'Chats'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (provider.friendRequests.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.friendRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Friends'),
                      if (provider.friends.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.friends.length}',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats Tab
          provider.chatRooms.isEmpty
              ? _emptyState('No chats yet')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: provider.chatRooms.length,
                  itemBuilder: (_, i) {
                    final roomData = provider.chatRooms[i];
                    final otherUser = roomData['otherUser'] as ChatUser;
                    final room = roomData['room'] as ChatRoom;
                    final lastMessage = roomData['lastMessage'] as ChatMessage?;
                    final unreadCount = roomData['unreadCount'] as int? ?? 0;

                    return _ChatTile(
                      title: otherUser.username ?? 'Unknown',
                      subtitle: lastMessage?.messageText ?? 'No messages yet',
                      avatarUrl: otherUser.avatarUrl,
                      time: lastMessage != null
                          ? DateFormat('HH:mm').format(lastMessage.createdAt)
                          : '',
                      unreadCount: unreadCount,
                      isOnline: otherUser.isOnline,
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrivateChatDetailScreen(
                              chatRoom: room,
                              otherUser: otherUser,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          // Received Requests Tab
          provider.friendRequests.isEmpty
              ? _emptyState('No friend requests')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: provider.friendRequests.length,
                  itemBuilder: (_, i) {
                    final requestData = provider.friendRequests[i];
                    final user = requestData['user'] as ChatUser;
                    final friendship = requestData['friendship'];

                    return _FriendRequestTile(
                      username: user.username ?? 'Unknown',
                      avatarUrl: user.avatarUrl,
                      onAccept: () async {
                        if (authProvider.userId != null) {
                          await provider.respondToRequest(
                            friendship.id,
                            true,
                            authProvider.userId!,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Friend request accepted!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      onDecline: () async {
                        if (authProvider.userId != null) {
                          // Show confirmation dialog
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Decline Friend Request'),
                              content: Text(
                                'Are you sure you want to decline friend request from ${user.username ?? 'Unknown'}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await provider.respondToRequest(
                              friendship.id,
                              false,
                              authProvider.userId!,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Friend request declined'),
                              ),
                            );
                          }
                        }
                      },
                    );
                  },
                ),
          // Friends Tab
          provider.friends.isEmpty
              ? _emptyState('No friends yet')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: provider.friends.length,
                  itemBuilder: (_, i) {
                    final friendData = provider.friends[i];
                    final user = friendData['user'] as ChatUser;

                    return _FriendTile(
                      username: user.username ?? 'Unknown',
                      avatarUrl: user.avatarUrl,
                      isOnline: user.isOnline,
                      onTap: () async {
                        if (authProvider.userId != null) {
                          // Create or get chat room
                          final room = await _chatService.getOrCreateChatRoom(
                            authProvider.userId!,
                            user.id,
                          );

                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrivateChatDetailScreen(
                                chatRoom: room,
                                otherUser: user,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Chat Tile Widget
class _ChatTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? avatarUrl;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final VoidCallback onTap;

  const _ChatTile({
    required this.title,
    required this.subtitle,
    this.avatarUrl,
    required this.time,
    this.unreadCount = 0,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          title[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Friend Request Tile Widget
class _FriendRequestTile extends StatefulWidget {
  final String username;
  final String? avatarUrl;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  const _FriendRequestTile({
    required this.username,
    this.avatarUrl,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<_FriendRequestTile> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
            child: widget.avatarUrl == null
                ? Text(
                    widget.username[0].toUpperCase(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.username,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            IconButton(
              onPressed: () async {
                setState(() => _isProcessing = true);
                try {
                  await widget.onAccept();
                } finally {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }
                }
              },
              icon: const Icon(Icons.check_circle, color: Colors.green),
            ),
            IconButton(
              onPressed: () async {
                setState(() => _isProcessing = true);
                try {
                  await widget.onDecline();
                } finally {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }
                }
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}

// Friend Tile Widget
class _FriendTile extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final VoidCallback onTap;

  const _FriendTile({
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          username[0].toUpperCase(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                username,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(Icons.chat_bubble_outline, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// Add Friend Bottom Sheet Widget
class _AddFriendBottomSheet extends StatefulWidget {
  const _AddFriendBottomSheet();

  @override
  State<_AddFriendBottomSheet> createState() => _AddFriendBottomSheetState();
}

class _AddFriendBottomSheetState extends State<_AddFriendBottomSheet> {
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  int _selectedTab = 0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Friend',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a friend by phone number or username.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            // Tab selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Phone Number',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Username',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: _selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Error message banner
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: const Icon(Icons.close, color: Colors.red, size: 18),
                    ),
                  ],
                ),
              ),
            // Input field
            if (_selectedTab == 0)
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+6281234567890 or 6281234567890',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
                      width: _errorMessage != null ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              )
            else
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : Colors.grey[300]!,
                      width: _errorMessage != null ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _errorMessage != null ? Colors.red : Colors.blue,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  // Validasi input
                  var input = _selectedTab == 0
                      ? _phoneController.text.trim()
                      : _usernameController.text.trim();

                  if (input.isEmpty) {
                    setState(() {
                      _errorMessage = _selectedTab == 0
                          ? 'Please enter a phone number'
                          : 'Please enter a username';
                    });
                    return;
                  }

                  // Normalize phone number: pastikan ada "+"
                  if (_selectedTab == 0 && !input.startsWith('+')) {
                    input = '+$input';
                  }

                  final authProvider = context.read<AuthProvider>();
                  final chatProvider = context.read<PrivateChatProvider>();

                  if (authProvider.userId == null) {
                    setState(() {
                      _errorMessage = 'User not logged in';
                    });
                    return;
                  }

                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  try {
                    await chatProvider.sendFriendRequest(
                      currentUserId: authProvider.userId!,
                      phoneNumber: _selectedTab == 0 ? input : null,
                      username: _selectedTab == 1 ? input : null,
                    );

                    if (!context.mounted) return;
                    setState(() => _isLoading = false);
                    Navigator.pop(context);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Friend request sent to ${_selectedTab == 0 ? input : '@$input'}!',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    // Parse error message untuk feedback yang lebih jelas
                    String errorMessage;
                    if (e.toString().contains('User not found')) {
                      errorMessage = _selectedTab == 0
                          ? 'Phone number not found in our system'
                          : 'Username not found in our system';
                    } else if (e.toString().contains('cannot add yourself')) {
                      errorMessage = 'You cannot add yourself as a friend';
                    } else if (e.toString().contains('already exists')) {
                      errorMessage = 'Friend request already sent to this user';
                    } else {
                      errorMessage = e.toString().replaceAll('Exception: ', '');
                    }

                    setState(() {
                      _isLoading = false;
                      _errorMessage = errorMessage;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Send Friend Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
