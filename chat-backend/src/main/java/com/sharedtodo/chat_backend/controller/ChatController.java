package com.sharedtodo.chat_backend.controller;

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
    // --- WebSocket ---
    @MessageMapping("/todolist/{todoListId}/send")
    public void sendMessageWS(@DestinationVariable String todoListId, ChatMessage message) {
        // Imposta ID e data
        message.setTodoListId(UUID.fromString(todoListId));
        if (message.getCreatedAt() == null) message.setCreatedAt(LocalDateTime.now());

        // Salva nel DB
        ChatMessage saved = chatMessageRepository.save(message);

        // Invia a tutti i client e include username
        messagingTemplate.convertAndSend(
            "/topic/todolist/" + todoListId,
            saved
        );
    }

    // --- REST: invio messaggi ---
    @PostMapping("/send")
    public ResponseEntity<ChatMessage> sendMessageREST(@RequestBody ChatMessageDTO dto) {
        if (dto.getContent() == null || dto.getUserId() == null || dto.getTodoListId() == null) {
            return ResponseEntity.badRequest().build();
        }

        ChatMessage message = new ChatMessage();
        message.setContent(dto.getContent());
        message.setUserId(UUID.fromString(dto.getUserId()));
        message.setTodoListId(UUID.fromString(dto.getTodoListId()));
        message.setUsername(dto.getUsername());
        message.setCreatedAt(LocalDateTime.now());

        ChatMessage saved = chatMessageRepository.save(message);

        // Pubblica via WebSocket per aggiornare tutti i client
        messagingTemplate.convertAndSend("/topic/todolist/" + dto.getTodoListId(), saved);

        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // --- REST: recupera cronologia ---
    @GetMapping("/todolist/{todoListId}")
    public List<ChatMessage> getMessages(@PathVariable UUID todoListId) {
        return chatMessageRepository.findAll().stream()
                .filter(msg -> msg.getTodoListId().equals(todoListId))
                .sorted((a, b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                .toList();
    }

    // DTO per ricevere messaggi REST
    public static class ChatMessageDTO {
        private String content;
        private String userId;
        private String todoListId;
        private String username;

        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        public String getTodoListId() { return todoListId; }
        public void setTodoListId(String todoListId) { this.todoListId = todoListId; }
        public String getUsername() { return username; }
        public void setUsername(String username) { this.username = username; }
    }
}
