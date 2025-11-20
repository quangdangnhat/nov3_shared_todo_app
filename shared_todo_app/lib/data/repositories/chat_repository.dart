import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';

class ChatRepository {
  final String _socketUrl = 'ws://localhost:8080/ws';
  StompClient? _client;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messagesController.stream;

  void connect(String todoListId) {
    if (_client != null && _client!.connected) return;

    _client = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (frame) {
          debugPrint('Connesso al backend Spring Boot Chat!');

          _client!.subscribe(
            destination: '/topic/todolist/$todoListId',
            callback: (frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                _messagesController.add(ChatMessage.fromMap(data));
              }
            },
          );
        },
        onWebSocketError: (error) => debugPrint('WebSocket error: $error'),
        onStompError: (frame) => debugPrint('STOMP error: ${frame.body}'),
        onDisconnect: (frame) => debugPrint('Disconnesso dal backend'),
      ),
    );

    _client?.activate();
  }

  void sendMessage(String todoListId, String content) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_client == null || !_client!.connected) return;

    final message = {
      'content': content,
      'userId': user.id, // necessario
      'username': user.userMetadata?['username'] ?? 'User',
    };

    _client!.send(
      destination: '/app/todolist/$todoListId/send',
      body: jsonEncode(message),
    );

    // Aggiungi subito il messaggio allo stream per il client stesso
    _messagesController.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      userId: user.id,
      todoListId: todoListId,
      createdAt: DateTime.now(),
      username: user.userMetadata?['username'] ?? 'User',
    ));
  }

  void dispose() {
    _client?.deactivate();
    _messagesController.close();
  }
}
