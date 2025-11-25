package com.sharedtodo.chat_backend.repository;

import com.sharedtodo.chat_backend.model.ChatMessage;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {
    List<ChatMessage> findByTodoListId(UUID todoListId); // non serve scrivere l'implementazione, Spring Data JPA la genera automaticamente
    /*
    Siccome al momento non sono necessarie query personalizzate, l'interfaccia rimane vuota.
    Siccome estendiamo da JpaRepository, ereditiamo metodi CRUD di base come:
    - save,
    - findById,
    - findAll,
    - deleteById,
    - ecc.

    In futuro, se dovessimo avere bisogno di query personalizzate, potremmo aggiungerle qui.
    */
}
