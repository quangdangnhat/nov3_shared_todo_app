class ChatMessage {
  final String id;
  final String content;
  final String userId;
  final String todoListId;
  final DateTime createdAt;
  // Opzionale: nome utente (se il backend lo manda o se lo recuperi localmente)
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
      userId: map['user_id'] ?? '',
      todoListId: map['todo_list_id'] ?? '',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      username: map['username'], // Se Spring Boot fa il join e lo manda
    );
  }
}