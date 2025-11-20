package com.sharedtodo.chat_backend.controller;

import com.sharedtodo.chat_backend.model.ChatMessage;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

@Controller
public class ChatController {

    private final SimpMessagingTemplate messagingTemplate;

    // Iniettiamo il template per inviare messaggi ai client connessi
    public ChatController(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    // Riceve un messaggio inviato dal client per una specifica to-do list e lo inoltra a tutti i client sottoscritti a quel topic.
    // Parametri:
    // - todoListId: Id della to-do list
    // - message:    Messaggio inviato dal client
    @MessageMapping("/todolist/{todoListId}/send")
    public void sendMessage(@DestinationVariable String todoListId, ChatMessage message) {
        // Invia il messaggio a tutti i client connessi a /topic/todolist/{todoListId}
        messagingTemplate.convertAndSend("/topic/todolist/" + todoListId, message);
    }
}
