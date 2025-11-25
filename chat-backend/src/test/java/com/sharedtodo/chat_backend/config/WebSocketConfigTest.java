package com.sharedtodo.chat_backend.config;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.StompWebSocketEndpointRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.messaging.simp.config.SimpleBrokerRegistration;

class WebSocketConfigTest {

    @Test
    void registerStompEndpoints_registersWsEndpoint() {
        WebSocketConfig config = new WebSocketConfig();

        StompEndpointRegistry registry = Mockito.mock(StompEndpointRegistry.class);
        StompWebSocketEndpointRegistration endpointRegistration = Mockito.mock(StompWebSocketEndpointRegistration.class);

        // Mockito: addEndpoint deve restituire il mock di StompWebSocketEndpointRegistration
        Mockito.when(registry.addEndpoint("/ws")).thenReturn(endpointRegistration);
        // setAllowedOriginPatterns restituisce sempre endpointRegistration (fluent API)
        Mockito.when(endpointRegistration.setAllowedOriginPatterns("http://localhost:8081"))
               .thenReturn(endpointRegistration);

        config.registerStompEndpoints(registry);

        Mockito.verify(registry).addEndpoint("/ws");
        Mockito.verify(endpointRegistration).setAllowedOriginPatterns("http://localhost:8081");
    }

    @Test
    void configureMessageBroker_enablesSimpleBrokerAndPrefix() {
        WebSocketConfig config = new WebSocketConfig();

        MessageBrokerRegistry registry = Mockito.mock(MessageBrokerRegistry.class);
        SimpleBrokerRegistration simpleBroker = Mockito.mock(SimpleBrokerRegistration.class);

        // enableSimpleBroker restituisce SimpleBrokerRegistration
        Mockito.when(registry.enableSimpleBroker("/topic")).thenReturn(simpleBroker);
        // setApplicationDestinationPrefixes restituisce MessageBrokerRegistry (fluent API)
        Mockito.when(registry.setApplicationDestinationPrefixes("/app")).thenReturn(registry);

        config.configureMessageBroker(registry);

        Mockito.verify(registry).enableSimpleBroker("/topic");
        Mockito.verify(registry).setApplicationDestinationPrefixes("/app");
    }
}
