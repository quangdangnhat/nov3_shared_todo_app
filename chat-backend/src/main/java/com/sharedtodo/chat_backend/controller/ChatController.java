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

    // WebSocket
    @MessageMapping("/todolist/{todoListId}/send")
    public void sendMessageWS(@DestinationVariable String todoListId, ChatMessage message) {
        message.setTodoListId(UUID.fromString(todoListId));
        if (message.getCreatedAt() == null) message.setCreatedAt(LocalDateTime.now());
        chatMessageRepository.save(message);
        messagingTemplate.convertAndSend("/topic/todolist/" + todoListId, message);
    }

    // REST: invio messaggio
    @PostMapping("/send")
    public ResponseEntity<ChatMessage> sendMessageREST(@RequestBody ChatMessageDTO dto) {
        try {
            ChatMessage msg = new ChatMessage();
            msg.setContent(dto.getContent());
            msg.setTodoListId(UUID.fromString(dto.getTodoListId()));
            msg.setUserId(UUID.fromString(dto.getUserId()));
            msg.setCreatedAt(LocalDateTime.now());
            ChatMessage saved = chatMessageRepository.save(msg);

            // Aggiorna anche WebSocket
            messagingTemplate.convertAndSend("/topic/todolist/" + dto.getTodoListId(), saved);

            return ResponseEntity.status(HttpStatus.CREATED).body(saved);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    // REST: recupero cronologia
    @GetMapping("/todolist/{todoListId}")
    public List<ChatMessage> getMessages(@PathVariable UUID todoListId) {
        return chatMessageRepository.findAll()
                .stream()
                .filter(msg -> msg.getTodoListId().equals(todoListId))
                .sorted((a,b) -> a.getCreatedAt().compareTo(b.getCreatedAt()))
                .toList();
    }

    // DTO per ricevere dati dal frontend come string UUID
    public static class ChatMessageDTO {
        private String content;
        private String userId;
        private String todoListId;

        public String getContent() { return content; }
        public void setContent(String content) { this.content = content; }
        public String getUserId() { return userId; }
        public void setUserId(String userId) { this.userId = userId; }
        public String getTodoListId() { return todoListId; }
        public void setTodoListId(String todoListId) { this.todoListId = todoListId; }
    }
}
