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

          _client?.subscribe(
            destination: '/topic/todolist/$todoListId',
            callback: (frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                final message = ChatMessage.fromMap(data);
                _messagesController.add(message);
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
    if (user == null) {
      debugPrint('Nessun utente loggato, impossibile inviare il messaggio');
      return;
    }

    if (_client == null || !_client!.connected) {
      debugPrint('WebSocket non connesso, impossibile inviare il messaggio');
      return;
    }

    _client?.send(
      destination: '/app/todolist/$todoListId/send',
      body: jsonEncode({
        'content': content,
        'user_id': user.id,
        'username': user.userMetadata?['username'] ?? 'Unknown',
      }),
    );
  }

  void dispose() {
    _client?.deactivate();
    _messagesController.close();
  }
}
