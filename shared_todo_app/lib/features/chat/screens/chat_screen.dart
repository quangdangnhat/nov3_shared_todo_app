import 'package:flutter/material.dart';
import '../../../data/models/chat.dart';
import '../../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String todoListId;

  const ChatScreen({super.key, required this.todoListId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _chatService.connect(widget.todoListId);

    _chatService.messageStream.listen((message) {
      if (message.todoListId == widget.todoListId) {
        setState(() => _messages.add(message));
      }
    });
  }

  Future<void> _loadHistory() async {
    final history = await _chatService.fetchHistory(widget.todoListId);
    setState(() => _messages.addAll(history));
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatService.sendMessage(widget.todoListId, text);
    _controller.clear();
  }

  @override
  void dispose() {
    _chatService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg.username ?? 'User'),
                  subtitle: Text(msg.content),
                  trailing: Text(
                    msg.createdAt.toLocal().toIso8601String().substring(11, 16),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Scrivi un messaggio'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
