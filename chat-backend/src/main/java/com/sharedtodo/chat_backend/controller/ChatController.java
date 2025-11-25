package com.sharedtodo.chat_backend.controller;

import com.sharedtodo.chat_backend.dto.ChatMessageDTO;
import com.sharedtodo.chat_backend.model.ChatMessage;
import com.sharedtodo.chat_backend.repository.ChatMessageRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    private final SimpMessagingTemplate messagingTemplate;
    private final ChatMessageRepository chatMessageRepository;

    public ChatController(SimpMessagingTemplate messagingTemplate, ChatMessageRepository chatMessageRepository) {
        this.messagingTemplate = messagingTemplate;
        this.chatMessageRepository = chatMessageRepository;
    }

    // --- WebSocket: invio messaggi ---
    @MessageMapping("/todolist/{todoListId}/send")
    public void sendMessageWS(@DestinationVariable String todoListId, ChatMessage message) {
        if (message == null || todoListId == null) return; // protezione null

        message.setTodoListId(UUID.fromString(todoListId));
        if (message.getCreatedAt() == null) message.setCreatedAt(LocalDateTime.now());

        ChatMessage saved = chatMessageRepository.save(message);

        messagingTemplate.convertAndSend("/topic/todolist/" + todoListId, saved);
    }

    // --- REST: invio messaggi ---
    @PostMapping("/send")
    public ResponseEntity<ChatMessage> sendMessageREST(@RequestBody ChatMessageDTO dto) {
        if (dto.getContent() == null || dto.getUserId() == null || dto.getTodoListId() == null || dto.getUsername() == null) {
            return ResponseEntity.badRequest().build();
        }

        ChatMessage message = new ChatMessage();
        message.setContent(dto.getContent());
        message.setUserId(UUID.fromString(dto.getUserId()));
        message.setTodoListId(UUID.fromString(dto.getTodoListId()));
        message.setUsername(dto.getUsername());
        message.setCreatedAt(LocalDateTime.now());

        ChatMessage saved = chatMessageRepository.save(message);
        messagingTemplate.convertAndSend("/topic/todolist/" + dto.getTodoListId(), saved);

        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // --- REST: recupera cronologia ---
    @GetMapping("/todolist/{todoListId}")
    public List<ChatMessage> getMessages(@PathVariable UUID todoListId) {
        if (todoListId == null) return List.of();

        return chatMessageRepository.findAll().stream()
                .filter(msg -> msg.getTodoListId() != null && msg.getTodoListId().equals(todoListId))
                .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                .toList();
    }
}
