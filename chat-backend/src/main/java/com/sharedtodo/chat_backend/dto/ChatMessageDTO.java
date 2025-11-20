package com.sharedtodo.chat_backend.dto;

import lombok.Data;

@Data
public class ChatMessageDTO {
    private String content;
    private String userId;      // stringa dal frontend
    private String todoListId;  // stringa dal frontend
    private String username;
}
