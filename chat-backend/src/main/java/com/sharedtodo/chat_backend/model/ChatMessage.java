package com.sharedtodo.chat_backend.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity // Dice a Spring: "Questa è una tabella nel DB"
@Table(name = "messages") // Il nome esatto della tabella su Supabase
@Data // Lombok: crea getter, setter e toString in automatico
@NoArgsConstructor // Crea costruttore vuoto
@AllArgsConstructor // Crea costruttore con tutti i parametri

public class ChatMessage {

    @Id // Chiave primaria
    @GeneratedValue(strategy = GenerationType.AUTO) // Supabase genera l'UUID
    private UUID id;

    @Column(name = "content", nullable = false)
    private String content;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "todo_list_id", nullable = false)
    private UUID todoListId;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    // Campo transitorio (non salvato nel DB, ma utile per inviare il nome al frontend)
    @Transient 
    private String username;

    // Metodo utile per impostare la data prima di salvare
    @PrePersist
    protected void onCreate() {
        if (this.createdAt == null) {
            this.createdAt = LocalDateTime.now();
        }
    }
}