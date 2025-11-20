import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Per prendere l'ID utente
import '../models/chat.dart';

class ChatRepository {
  // Se usi l'emulatore Android: 'ws://10.0.2.2:8080/ws'
  // Se usi Chrome/Web o iOS Simulator: 'ws://localhost:8080/ws'
  final String _socketUrl = 'ws://localhost:8080/ws'; 
  
  StompClient? _client;
  final _messagesController = StreamController<ChatMessage>.broadcast();
  
  // Stream da ascoltare nella UI
  Stream<ChatMessage> get messageStream => _messagesController.stream;

  void connect(String todoListId) {
    if (_client != null && _client!.connected) return;

    final myUserId = Supabase.instance.client.auth.currentUser?.id;

    _client = StompClient(
      config: StompConfig(
        url: _socketUrl,
        onConnect: (StompFrame frame) {
          debugPrint('Connected to Spring Boot Chat!');
          
          // Iscriviti al canale specifico di questa Todo List
          _client?.subscribe(
            destination: '/topic/chat/$todoListId', 
            callback: (StompFrame frame) {
              if (frame.body != null) {
                final data = jsonDecode(frame.body!);
                final message = ChatMessage.fromMap(data);
                _messagesController.add(message);
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => debugPrint('WebSocket error: $error'),
      ),
    );

    _client?.activate();
  }

  void sendMessage(String todoListId, String content) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Invia il messaggio a Spring Boot
    _client?.send(
      destination: '/app/sendMessage', // L'endpoint @MessageMapping in Spring
      body: jsonEncode({
        'content': content,
        'todo_list_id': todoListId,
        'user_id': user.id, // Spring Boot userà questo per salvare nel DB
        'username': user.userMetadata?['username'] ?? 'Unknown', // Utile per la UI immediata
      }),
    );
  }

  void dispose() {
    _client?.deactivate();
    _messagesController.close();
  }
}