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

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      userId: map['userId'] ?? map['user_id'] ?? '',
      todoListId: map['todoListId'] ?? map['todo_list_id'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
      username: map['username'] ?? 'User',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'user_id': userId,
      'todo_list_id': todoListId,
      'created_at': createdAt.toIso8601String(),
      'username': username,
    };
  }
}
