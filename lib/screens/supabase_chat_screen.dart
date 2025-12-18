import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../services/chat_service.dart';
import '../services/user_service.dart';

class SupabaseChatScreen extends StatefulWidget {
  final ChatUser otherUser;

  const SupabaseChatScreen({
    super.key,
    required this.otherUser,
  });

  @override
  State<SupabaseChatScreen> createState() => _SupabaseChatScreenState();
}

class _SupabaseChatScreenState extends State<SupabaseChatScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final TextEditingController _messageController = TextEditingController();

  ChatUser? _currentUser;
  ChatRoom? _chatRoom;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isOtherUserTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get current user
      _currentUser = await _userService.getCurrentUser();
      if (_currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Get or create chat room
      _chatRoom = await _chatService.getOrCreateChatRoom(
        _currentUser!.id,
        widget.otherUser.id,
      );

      // Load messages
      await _loadMessages();

      // Mark messages as read
      await _chatService.markMessagesAsRead(_chatRoom!.id, _currentUser!.id);

      // Subscribe to realtime messages
      _chatService.subscribeToMessages(_chatRoom!.id);
      _chatService.messagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          _chatService.markMessagesAsRead(_chatRoom!.id, _currentUser!.id);
        }
      });

      // Subscribe to typing status
      _chatService.subscribeToTypingStatus(_chatRoom!.id, _currentUser!.id);
      _chatService.typingStatusStream.listen((typingStatus) {
        if (mounted) {
          setState(() {
            _isOtherUserTyping = typingStatus[widget.otherUser.id] ?? false;
          });
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    if (_chatRoom == null) return;

    try {
      final messages = await _chatService.getMessages(_chatRoom!.id);
      setState(() {
        _messages = messages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty ||
        _currentUser == null ||
        _chatRoom == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Stop typing indicator
    await _chatService.updateTypingStatus(
      chatRoomId: _chatRoom!.id,
      userId: _currentUser!.id,
      isTyping: false,
    );

    try {
      await _chatService.sendMessage(
        chatRoomId: _chatRoom!.id,
        senderId: _currentUser!.id,
        receiverId: widget.otherUser.id,
        messageText: messageText,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _onTyping(String text) {
    if (_chatRoom == null || _currentUser == null) return;

    _chatService.updateTypingStatus(
      chatRoomId: _chatRoom!.id,
      userId: _currentUser!.id,
      isTyping: text.isNotEmpty,
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUser.avatarUrl != null
                  ? NetworkImage(widget.otherUser.avatarUrl!)
                  : null,
              child: widget.otherUser.avatarUrl == null
                  ? Text(widget.otherUser.displayName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.displayName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    widget.otherUser.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.otherUser.isOnline
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text('No messages yet. Start chatting!'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isMe = message.senderId == _currentUser!.id;

                            return _buildMessageBubble(message, isMe);
                          },
                        ),
                ),
                if (_isOtherUserTyping)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          '${widget.otherUser.displayName} is typing...',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildMessageInput(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.messageText,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: _onTyping,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
