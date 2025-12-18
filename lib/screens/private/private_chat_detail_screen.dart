import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/chat_user.dart';
import '../../models/chat_room.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/image_service.dart';

class PrivateChatDetailScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final ChatUser otherUser;

  const PrivateChatDetailScreen({
    super.key,
    required this.chatRoom,
    required this.otherUser,
  });

  @override
  State<PrivateChatDetailScreen> createState() =>
      _PrivateChatDetailScreenState();
}

class _PrivateChatDetailScreenState extends State<PrivateChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImageService _imageService = ImageService();

  PrivateChatProvider? _chatProvider;
  String? _currentUserId;
  bool _isInitialized = false;
  int _previousMessageCount = 0;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Enter chat when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          final authProvider = context.read<AuthProvider>();
          _currentUserId = authProvider.userId;

          if (_currentUserId != null) {
            _chatProvider = context.read<PrivateChatProvider>();
            _chatProvider!.enterChat(widget.chatRoom.id, _currentUserId!);

            // Add listener for auto-scroll on new messages
            _chatProvider!.addListener(_onMessagesChanged);

            setState(() {
              _isInitialized = true;
            });
          }
        } catch (e) {
          debugPrint('Error entering chat: $e');
        }
      }
    });
  }

  void _onMessagesChanged() {
    if (!mounted) return;

    final currentCount = _chatProvider?.activeChatMessages.length ?? 0;
    if (currentCount > _previousMessageCount) {
      // New message received, scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    }
    _previousMessageCount = currentCount;
  }

  @override
  void dispose() {
    _chatProvider?.removeListener(_onMessagesChanged);
    _chatProvider?.leaveChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              widget.otherUser.username ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              widget.otherUser.isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                color: widget.otherUser.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Block User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_isInitialized
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Consumer<PrivateChatProvider>(
                    builder: (context, provider, child) {
                      final messages = provider.activeChatMessages;

                      if (messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.waving_hand,
                                size: 48,
                                color: Colors.yellow[700],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Say Hello! 👋',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start the conversation with ${widget.otherUser.username}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg.isMe(_currentUserId ?? '');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (!isMe) ...[
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: widget.otherUser.avatarUrl != null
                                        ? NetworkImage(widget.otherUser.avatarUrl!)
                                        : null,
                                    child: widget.otherUser.avatarUrl == null
                                        ? Text(
                                            (widget.otherUser.username ?? 'U')[0].toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue : Colors.grey[100],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(20),
                                      topRight: const Radius.circular(20),
                                      bottomLeft: isMe
                                          ? const Radius.circular(20)
                                          : const Radius.circular(4),
                                      bottomRight: isMe
                                          ? const Radius.circular(4)
                                          : const Radius.circular(20),
                                    ),
                                    boxShadow: [
                                      if (isMe)
                                        BoxShadow(
                                          color: Colors.blue.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image or Text message
                                      if (msg.messageType == 'image')
                                        _buildImageMessage(msg.content, isMe)
                                      else
                                        Text(
                                          msg.content,
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('HH:mm').format(msg.timestamp),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Build image message widget
  Widget _buildImageMessage(String imageUrl, bool isMe) {
    return GestureDetector(
      onTap: () => _showFullImage(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: isMe ? Colors.white : Colors.blue,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 200,
              height: 200,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }

  // Show full screen image
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick and send image
  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_currentUserId == null) return;

    setState(() => _isUploadingImage = true);

    try {
      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploading image...'),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final imageUrl = await _imageService.pickCompressAndUpload(
        userId: _currentUserId!,
        source: source,
      );

      if (imageUrl != null && mounted) {
        // Hide uploading indicator
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Send image message
        context.read<PrivateChatProvider>().sendMessage(
          chatRoomId: widget.chatRoom.id,
          senderId: _currentUserId!,
          receiverId: widget.otherUser.id,
          messageText: imageUrl,
          messageType: 'image',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add, color: Colors.grey),
              onPressed: _isUploadingImage ? null : _showImagePickerOptions,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50], // Very light grey
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue, // Primary color
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Block this user?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You will no longer receive messages from this user.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _showReportBottomSheet();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Block User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportBottomSheet() {
    String? selectedReason;
    final TextEditingController detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                      'Report User',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please select a reason for your report.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildReportOption(
                      'Harassment',
                      selectedReason,
                      (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                    _buildReportOption(
                      'Spam',
                      selectedReason,
                      (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                    _buildReportOption(
                      'Hate Speech',
                      selectedReason,
                      (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                    _buildReportOption(
                      'Inappropriate Content',
                      selectedReason,
                      (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                    _buildReportOption(
                      'Other',
                      selectedReason,
                      (value) {
                        setModalState(() => selectedReason = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Please provide details...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedReason != null && _currentUserId != null) {
                            // Save contexts before async operations
                            final navigatorContext = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(context);

                            // Close bottom sheet first
                            navigatorContext.pop();

                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              // Block user
                              await _chatProvider?.blockUser(
                                currentUserId: _currentUserId!,
                                blockedUserId: widget.otherUser.id,
                                reason: selectedReason,
                              );

                              if (mounted) {
                                // Close loading dialog
                                navigatorContext.pop();

                                // Show success message
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'User blocked and reported for: $selectedReason',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Return to previous screen (chat list)
                                navigatorContext.pop();
                              }
                            } catch (e) {
                              if (mounted) {
                                // Close loading dialog
                                navigatorContext.pop();

                                // Show error message
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to block user: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Send Report',
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
          },
        );
      },
    ).whenComplete(() {
      detailsController.dispose();
    });
  }

  Widget _buildReportOption(
    String label,
    String? selectedValue,
    Function(String) onChanged,
  ) {
    final isSelected = selectedValue == label;
    return GestureDetector(
      onTap: () => onChanged(label),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withValues(alpha: 0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2196F3) : Colors.grey[400]!,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _currentUserId != null) {
      context.read<PrivateChatProvider>().sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: _currentUserId!,
        receiverId: widget.otherUser.id,
        messageText: text,
      );
      _messageController.clear();
    }
  }
}
