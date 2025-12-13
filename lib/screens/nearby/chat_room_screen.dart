import 'dart:async';
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

  @override
  void initState() {
    super.initState();

    _myBubbleColor = widget.room.themeColor ?? const Color(0xFF2196F3);
    _otherBubbleColor = Colors.grey.shade200;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NearbyProvider>(
        context,
        listen: false,
      ).joinRoom(widget.room.id);
    });

    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    Provider.of<NearbyProvider>(context, listen: false).leaveRoom();
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
      senderHandle: authProvider.user?.anonHandle ?? 'Anonymous',
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
