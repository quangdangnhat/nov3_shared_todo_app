package com.sharedtodo.chat_backend.repository;

import com.sharedtodo.chat_backend.model.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {
}
