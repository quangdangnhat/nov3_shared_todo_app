import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/chat.dart';
import '../../../../data/repositories/chat_repository.dart'; // O ChatService se lo chiami così

class ChatDialog extends StatefulWidget {
  final String todoListId;

  const ChatDialog({
    super.key,
    required this.todoListId,
  });

  @override
  State<ChatDialog> createState() => _ChatDialogState();
}

class _ChatDialogState extends State<ChatDialog> {
  final ChatRepository _chatService = ChatRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    // --- 1. Carica lo storico dal REST ---
    final history = await _chatService.fetchHistory(widget.todoListId);
    if (!mounted) return;
    setState(() {
      _messages.addAll(
          history); // Assumiamo che sia ordinato dal più vecchio al più recente
    });

    // Scrolla in basso dopo il primo render
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // --- 2. Connetti al WebSocket ---
    _chatService.connect(widget.todoListId);

    // --- 3. Ascolta i nuovi messaggi ---
    _chatService.messageStream.listen((message) {
      if (!mounted) return;
      if (message.todoListId == widget.todoListId) {
        setState(() {
          _messages.add(message); // Aggiungi in fondo
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: size.width > 600 ? 500 : size.width * 0.95,
        height: size.height * 0.8,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chat', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Lista messaggi
            Expanded(
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet.\nStart the conversation!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      reverse: false, // Ordine cronologico corretto
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final currentUserId = _chatService
                            .getCurrentUserId(); // Metodo da implementare
                        final isMe = msg.userId == currentUserId;
                        return _buildMessageBubble(context, msg, isMe);
                      },
                    ),
            ),
            const Divider(height: 1),

            // Input field
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe && msg.username != null)
              Text(
                msg.username!,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .onSecondaryContainer
                      .withOpacity(0.7),
                ),
              ),
            Text(
              msg.content,
              style: TextStyle(
                color: isMe
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(msg.createdAt.toLocal()),
              style: TextStyle(
                fontSize: 9,
                color: (isMe
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSecondaryContainer)
                    .withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
