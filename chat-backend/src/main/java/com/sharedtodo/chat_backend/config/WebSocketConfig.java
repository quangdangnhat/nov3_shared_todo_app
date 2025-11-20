package com.sharedtodo.chat_backend.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker // Dice a Spring: "Attiva WebSocket con supporto STOMP"
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {
    // Qui configuriamo i topic e il broker semplice (per i messaggi)
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic"); // i client si sottoscrivono a /topic/todolist/{todoListId}
        config.setApplicationDestinationPrefixes("/app"); 
    }

    // Qui definiamo l'endpoint WebSocket a cui i client si connettono
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws") // URL WebSocket: ws://host:8080/ws
                .setAllowedOriginPatterns("*") // Consente connessioni da qualsiasi origine (frontend Flutter)
                .withSockJS(); // fallback automatico se WebSocket non è disponibile
    }
}
