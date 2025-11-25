package com.sharedtodo.chat_backend.model;

import org.junit.jupiter.api.Test;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class ChatMessageTest {

    @Test
    void prePersist_setsCreatedAtIfNull() {
        ChatMessage message = new ChatMessage();
        message.setContent("Hello");
        message.setUserId(UUID.randomUUID());
        message.setTodoListId(UUID.randomUUID());
        message.setUsername("Pippo");

        assertThat(message.getCreatedAt()).isNull();

        // Simula la chiamata JPA al prePersist
        message.prePersist();

        assertThat(message.getCreatedAt()).isNotNull();
    }

    @Test
    void prePersist_doesNotOverwriteCreatedAt() {
        ChatMessage message = new ChatMessage();
        LocalDateTime dt = LocalDateTime.of(2025, 1, 1, 12, 0);
        message.setCreatedAt(dt);

        message.prePersist();

        assertThat(message.getCreatedAt()).isEqualTo(dt);
    }


    @Test
    void settersAndGetters_workForTransientField() {
        ChatMessage message = new ChatMessage();
        message.setUsername("Mario");
        assertThat(message.getUsername()).isEqualTo("Mario");
    }

    @Test
    void allArgsConstructor_setsAllFields() {
        UUID id = UUID.randomUUID();
        UUID userId = UUID.randomUUID();
        UUID todoListId = UUID.randomUUID();
        LocalDateTime now = LocalDateTime.now();
        ChatMessage message = new ChatMessage();

        message.setId(id);
        message.setContent("Test");
        message.setUserId(userId);
        message.setTodoListId(todoListId);
        message.setCreatedAt(now);
        message.setUsername("Luigi");

        assertThat(message.getId()).isEqualTo(id);
        assertThat(message.getContent()).isEqualTo("Test");
        assertThat(message.getUserId()).isEqualTo(userId);
        assertThat(message.getTodoListId()).isEqualTo(todoListId);
        assertThat(message.getCreatedAt()).isEqualTo(now);
        assertThat(message.getUsername()).isEqualTo("Luigi");

    }
}
