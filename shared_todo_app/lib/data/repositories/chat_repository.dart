import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';

class ChatRepository {
  // URL del WebSocket (Spring Boot)
  final String _socketUrl = 'ws://localhost:8080/ws';

  // URL base per le API REST
  final String _baseUrl = 'http://localhost:8080/api';

  StompClient? _client;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get messageStream => _messagesController.stream;

  // Lista interna per memorizzare lo storico dei messaggi
  final List<ChatMessage> _allMessages = [];

  /// Connette al WebSocket e si iscrive al topic della lista
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
                final msg = ChatMessage.fromMap(data);

                _allMessages.add(msg);
                // Ordina sempre in ordine cronologico
                _allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

                _messagesController.add(msg);
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

  /// Invia un messaggio tramite WebSocket
  void sendMessage(String todoListId, String content) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (_client == null || !_client!.connected) {
      debugPrint('Errore: Client non connesso');
      return;
    }

    final message = {
      'content': content,
      'userId': user.id,
      'username': user.userMetadata?['username'] ?? 'User',
    };

    _client!.send(
      destination: '/app/todolist/$todoListId/send',
      body: jsonEncode(message),
    );
  }

  /// Recupera la cronologia dei messaggi via REST
  Future<List<ChatMessage>> fetchHistory(String todoListId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/todolist/$todoListId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final messages = data.map((json) => ChatMessage.fromMap(json)).toList();

        // Ordina in ordine cronologico
        //messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Aggiorna la lista interna
        _allMessages.clear();
        _allMessages.addAll(messages);

        return messages;
      } else {
        debugPrint('Failed to fetch history: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  /// Restituisce tutti i messaggi memorizzati localmente
  List<ChatMessage> get allMessages => List.unmodifiable(_allMessages);
  String? getCurrentUserId() {
    return Supabase.instance.client.auth.currentUser?.id;
  }

  void dispose() {
    _client?.deactivate();
    _messagesController.close();
    _allMessages.clear();
  }
}
