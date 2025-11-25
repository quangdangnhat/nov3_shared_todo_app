package com.sharedtodo.chat_backend.controller;

import com.sharedtodo.chat_backend.dto.ChatMessageDTO;
import com.sharedtodo.chat_backend.model.ChatMessage;
import com.sharedtodo.chat_backend.repository.ChatMessageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ChatControllerTest {

    private ChatMessageRepository repository;
    private SimpMessagingTemplate messagingTemplate;
    private ChatController controller;

    @BeforeEach
    void setup() {
        repository = mock(ChatMessageRepository.class);
        messagingTemplate = mock(SimpMessagingTemplate.class);
        controller = new ChatController(messagingTemplate, repository);
    }

    // --- sendMessageWS ---
    @Test
    void sendMessageWS_savesAndSendsMessage() {
        ChatMessage message = new ChatMessage();
        String todoListId = UUID.randomUUID().toString();

        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        controller.sendMessageWS(todoListId, message);

        assertThat(message.getTodoListId().toString()).isEqualTo(todoListId);
        assertThat(message.getCreatedAt()).isNotNull();

        verify(repository).save(message);
        verify(messagingTemplate).convertAndSend("/topic/todolist/" + todoListId, message);
    }

    @Test
    void sendMessageWS_nullMessage() {
        String todoListId = UUID.randomUUID().toString();
        controller.sendMessageWS(todoListId, null);
        verifyNoInteractions(repository, messagingTemplate);
    }

    @Test
    void sendMessageWS_nullTodoListId() {
        ChatMessage message = new ChatMessage();
        controller.sendMessageWS(null, message);
        assertThat(message.getTodoListId()).isNull();
        verifyNoInteractions(repository, messagingTemplate);
    }

    // --- sendMessageREST ---
    @Test
    void sendMessageREST_success() {
        ChatMessageDTO dto = new ChatMessageDTO();
        dto.setContent("Hello");
        dto.setUserId(UUID.randomUUID().toString());
        dto.setTodoListId(UUID.randomUUID().toString());
        dto.setUsername("Pippo");

        when(repository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        ResponseEntity<ChatMessage> response = controller.sendMessageREST(dto);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.CREATED);
        ChatMessage savedMessage = response.getBody();
        assertThat(savedMessage).isNotNull();
        assertThat(savedMessage.getContent()).isEqualTo("Hello");
        assertThat(savedMessage.getUsername()).isEqualTo("Pippo");

        verify(repository).save(savedMessage);
        verify(messagingTemplate).convertAndSend("/topic/todolist/" + dto.getTodoListId(), savedMessage);
    }

    @Test
    void sendMessageREST_badRequest() {
        ResponseEntity<ChatMessage> response = controller.sendMessageREST(new ChatMessageDTO());
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(repository, messagingTemplate);
    }

    @Test
    void sendMessageREST_partialNullFields() {
        ChatMessageDTO dto = new ChatMessageDTO();
        dto.setContent("Hello");
        dto.setUserId(UUID.randomUUID().toString());
        // dto.setTodoListId null
        ResponseEntity<ChatMessage> response = controller.sendMessageREST(dto);
        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(repository, messagingTemplate);
    }

    // --- getMessages ---
    @Test
    void getMessages_filtersAndSorts() {
        UUID todoListId = UUID.randomUUID();

        ChatMessage m1 = new ChatMessage();
        m1.setTodoListId(todoListId);
        m1.setCreatedAt(LocalDateTime.now().minusMinutes(5));

        ChatMessage m2 = new ChatMessage();
        m2.setTodoListId(todoListId);
        m2.setCreatedAt(LocalDateTime.now());

        ChatMessage m3 = new ChatMessage();
        m3.setTodoListId(UUID.randomUUID()); // diverso todoListId
        m3.setCreatedAt(LocalDateTime.now());

        when(repository.findAll()).thenReturn(List.of(m1, m2, m3));

        List<ChatMessage> result = controller.getMessages(todoListId);

        // Ora i messaggi dovrebbero essere m1 e m2, ordinati per createdAt
        assertThat(result).containsExactly(m1, m2);
    }

    @Test
    void getMessages_nullTodoListId() {
        List<ChatMessage> result = controller.getMessages(null);
        assertThat(result).isEmpty();
    }

    @Test
    void getMessages_messageWithNullTodoListId() {
        UUID todoListId = UUID.randomUUID();
        ChatMessage m1 = new ChatMessage();
        m1.setTodoListId(null);
        m1.setCreatedAt(LocalDateTime.now());

        when(repository.findAll()).thenReturn(List.of(m1));

        List<ChatMessage> result = controller.getMessages(todoListId);
        assertThat(result).isEmpty();
    }
}
