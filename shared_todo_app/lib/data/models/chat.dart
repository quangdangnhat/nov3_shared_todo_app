class ChatMessage {
  final String id;
  final String content;
  final String userId;
  final String todoListId;
  final DateTime createdAt;
  final String? username;

  ChatMessage({
    required this.id,
    required this.content,
    required this.userId,
    required this.todoListId,
    required this.createdAt,
    this.username,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
        id: map['id'] ?? '',
        content: map['content'] ?? '',
        userId: map['userId'] ?? '',
        todoListId: map['todoListId'] ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
        username: map['username'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'userId': userId,
        'todoListId': todoListId,
        'createdAt': createdAt.toIso8601String(),
        'username': username,
      };
}
