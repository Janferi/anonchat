class MessageModel {
  final String id;
  final String senderHandle;
  final String content;
  final DateTime timestamp;
  final bool isMe;

  MessageModel({
    required this.id,
    required this.senderHandle,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });
}
