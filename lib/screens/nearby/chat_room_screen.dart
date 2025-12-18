import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat_room_model.dart';
import '../../providers/nearby_provider.dart';
import '../../providers/auth_provider.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isTyping = false;
  bool _showNewMessageBadge = false;
  int _lastMessageCount = 0;

  late final Color _myBubbleColor;
  late final Color _otherBubbleColor;

  NearbyProvider? _nearbyProvider;

  @override
  void initState() {
    super.initState();

    _myBubbleColor = widget.room.themeColor ?? const Color(0xFF2196F3);
    _otherBubbleColor = Colors.grey.shade200;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nearbyProvider = Provider.of<NearbyProvider>(
        context,
        listen: false,
      );
      _nearbyProvider!.joinRoom(widget.room.id);
    });

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _nearbyProvider?.leaveRoom();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final atBottom =
        _scrollController.offset >=
        _scrollController.position.maxScrollExtent - 50;

    if (atBottom && _showNewMessageBadge) {
      setState(() => _showNewMessageBadge = false);
    }
  }

  void _handleNewMessages(NearbyProvider provider) {
    if (provider.messages.length > _lastMessageCount) {
      final atBottom =
          _scrollController.hasClients &&
          _scrollController.offset >=
              _scrollController.position.maxScrollExtent - 50;

      if (!atBottom) {
        setState(() => _showNewMessageBadge = true);
      } else {
        _scrollToBottom();
      }
    }

    _lastMessageCount = provider.messages.length;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Color _getAvatarColor(String handle) {
    final colors = [
      const Color(0xFF6200EA),
      const Color(0xFF0091EA),
      const Color(0xFF00C853),
      const Color(0xFFFF6D00),
      const Color(0xFFD50000),
      const Color(0xFF6200EA),
      const Color(0xFF0091EA),
    ];
    final index = handle.hashCode % colors.length;
    return colors[index.abs()];
  }

  void _showUserBottomSheet(String userHandle) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: _getAvatarColor(userHandle),
                child: Text(
                  userHandle.isNotEmpty ? userHandle[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userHandle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildBottomSheetOption(
                icon: Icons.send,
                label: 'Send Private Message',
                iconColor: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildBottomSheetOption(
                icon: Icons.block,
                label: 'Block User',
                iconColor: Colors.purple,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildBottomSheetOption(
                icon: Icons.flag,
                label: 'Report User',
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _sendMessageOptimistic(
    NearbyProvider nearbyProvider,
    AuthProvider authProvider,
  ) {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    nearbyProvider.sendMessageOptimistic(
      roomId: widget.room.id,
      content: content,
      senderHandle: authProvider.user?.username ?? 'Anonymous',
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyProvider = Provider.of<NearbyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _handleNewMessages(nearbyProvider),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.room.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '${nearbyProvider.memberCount} members',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildMessageList(nearbyProvider)),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputBar(nearbyProvider, authProvider),
            ],
          ),

          /// 🔔 New Message Badge
          if (_showNewMessageBadge)
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _scrollToBottom();
                    setState(() => _showNewMessageBadge = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'New messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================
  // MESSAGE LIST
  // =========================
  Widget _buildMessageList(NearbyProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final msg = provider.messages[index];
        final isMe = msg.isMe;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                GestureDetector(
                  onTap: () => _showUserBottomSheet(msg.senderHandle),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: _getAvatarColor(msg.senderHandle),
                    child: Text(
                      msg.senderHandle.isNotEmpty
                          ? msg.senderHandle[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMe
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _buildBubble(msg, isMe),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(msg.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubble(dynamic message, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? _myBubbleColor : _otherBubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: isMe
              ? const Radius.circular(20)
              : const Radius.circular(6),
          bottomRight: isMe
              ? const Radius.circular(6)
              : const Radius.circular(20),
        ),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ),
    );
  }

  // =========================
  // INPUT BAR
  // =========================
  Widget _buildInputBar(
    NearbyProvider nearbyProvider,
    AuthProvider authProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (val) {
                setState(() => _isTyping = val.isNotEmpty);
              },
              onSubmitted: (_) =>
                  _sendMessageOptimistic(nearbyProvider, authProvider),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () =>
                  _sendMessageOptimistic(nearbyProvider, authProvider),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // TYPING INDICATOR
  // =========================
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8),
      child: Row(
        children: const [
          Text(
            'Someone is typing',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 6),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}
