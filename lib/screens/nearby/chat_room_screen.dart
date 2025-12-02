import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/chat_room_model.dart';
import '../../providers/nearby_provider.dart';
import '../report/report_user_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  final ChatRoomModel room;

  const ChatRoomScreen({super.key, required this.room});

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NearbyProvider>(
        context,
        listen: false,
      ).joinRoom(widget.room.id);
    });
  }

  @override
  void deactivate() {
    Provider.of<NearbyProvider>(context, listen: false).leaveRoom();
    super.deactivate();
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
    final nearbyProvider = Provider.of<NearbyProvider>(context);

    // Auto scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: nearbyProvider.messages.length,
              itemBuilder: (context, index) {
                final message = nearbyProvider.messages[index];
                return Align(
                  alignment: message.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      if (!message.isMe) {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(
                                    Icons.flag,
                                    color: Colors.red,
                                  ),
                                  title: Text('Report ${message.senderHandle}'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReportUserScreen(
                                          userId: message.senderHandle,
                                          userHandle: message.senderHandle,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isMe
                            ? Colors.blue[100]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!message.isMe)
                            Text(
                              message.senderHandle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          Text(message.content),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    final content = _messageController.text.trim();
                    if (content.isNotEmpty) {
                      nearbyProvider.sendMessage(widget.room.id, content);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
