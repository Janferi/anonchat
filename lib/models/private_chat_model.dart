class PrivateChatModel {
  final String id;
  final String otherUserHandle;
  final String otherUserId;
  final String lastMessage;
  final DateTime lastMessageTime;

  PrivateChatModel({
    required this.id,
    required this.otherUserHandle,
    required this.otherUserId,
    required this.lastMessage,
    required this.lastMessageTime,
  });
}
