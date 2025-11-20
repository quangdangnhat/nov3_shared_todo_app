import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/models/chat.dart';
import '../data/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final ChatRepository _repository = ChatRepository();

  Stream<ChatMessage> get messageStream => _repository.messageStream;

  void connect(String todoListId) {
    _repository.connect(todoListId);
  }

  void dispose() {
    _repository.dispose();
  }

  Future<void> sendMessage(String todoListId, String content) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final payload = {
      'content': content,
      'userId': user.id,
      'todoListId': todoListId,
      'username': user.userMetadata?['username'] ?? 'User',
    };

    final url = Uri.parse('http://localhost:8080/api/chat/send');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Messaggio inviato con successo');
      } else {
        debugPrint('Errore invio messaggio: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception invio messaggio: $e');
    }
  }

  Future<List<ChatMessage>> fetchHistory(String todoListId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final url =
        Uri.parse('http://localhost:8080/api/chat/todolist/$todoListId');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => ChatMessage.fromMap(e)).toList();
      } else {
        debugPrint('Errore fetchHistory: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Exception fetchHistory: $e');
      return [];
    }
  }
}
