package com.sharedtodo.chat_backend.dto;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class ChatMessageDTOTest {

    @Test
    void gettersAndSetters_work() {
        ChatMessageDTO dto = new ChatMessageDTO();

        dto.setContent("Hello");
        dto.setUserId("123");
        dto.setTodoListId("456");
        dto.setUsername("Pippo");

        assertThat(dto.getContent()).isEqualTo("Hello");
        assertThat(dto.getUserId()).isEqualTo("123");
        assertThat(dto.getTodoListId()).isEqualTo("456");
        assertThat(dto.getUsername()).isEqualTo("Pippo");
    }

    @Test
    void equalsAndHashCode_work() {
        ChatMessageDTO dto1 = new ChatMessageDTO();
        dto1.setContent("A");
        dto1.setUserId("1");

        ChatMessageDTO dto2 = new ChatMessageDTO();
        dto2.setContent("A");
        dto2.setUserId("1");

        assertThat(dto1).isEqualTo(dto2);
        assertThat(dto1.hashCode()).isEqualTo(dto2.hashCode());
    }
}
