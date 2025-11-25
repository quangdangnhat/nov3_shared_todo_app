package com.sharedtodo.chat_backend.repository;

import com.sharedtodo.chat_backend.model.ChatMessage;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.ANY)
class ChatMessageRepositoryTest {

    @Autowired private ChatMessageRepository repository;
    @Autowired private EntityManager entityManager;

    private ChatMessage createSampleMessage() {
        ChatMessage msg = new ChatMessage();
        msg.setContent("Hello world");
        msg.setUserId(UUID.randomUUID());
        msg.setTodoListId(UUID.randomUUID());
        msg.setUsername("Pippo"); // username ora persistente
        return msg;
    }

    // --- Save & Find ---
    @Test
    void testSaveAndFindById() {
        ChatMessage saved = repository.save(createSampleMessage());
        assertThat(saved.getId()).isNotNull();

        Optional<ChatMessage> found = repository.findById(saved.getId());
        assertThat(found).isPresent();
    }

    @Test
    void testFindById_nonExisting() {
        Optional<ChatMessage> found = repository.findById(UUID.randomUUID());
        assertThat(found).isEmpty();
    }

    @Test
    void testCreatedAtIsGeneratedByPrePersist() {
        ChatMessage saved = repository.save(createSampleMessage());
        assertThat(saved.getCreatedAt()).isNotNull();
    }

    // --- Username persistente ---
    @Test
    void testUsernameIsPersisted() {
        ChatMessage message = createSampleMessage();

        ChatMessage saved = repository.save(message);

        entityManager.flush();
        entityManager.clear();

        ChatMessage reloaded = repository.findById(saved.getId()).orElseThrow();
        assertThat(reloaded.getUsername()).isEqualTo("Pippo");
    }

    // --- Find all ---
    @Test
    void testFindAll() {
        repository.save(createSampleMessage());
        repository.save(createSampleMessage());
        List<ChatMessage> list = repository.findAll();
        assertThat(list).hasSize(2);
    }

    @Test
    void testFindAll_empty() {
        List<ChatMessage> list = repository.findAll();
        assertThat(list).isEmpty();
    }

    // --- Delete ---
    @Test
    void testDeleteById_existing() {
        ChatMessage saved = repository.save(createSampleMessage());
        repository.deleteById(saved.getId());
        assertThat(repository.findById(saved.getId())).isEmpty();
    }

    @Test
    void testDeleteById_nonExisting() {
        UUID randomId = UUID.randomUUID();
        // Non deve lanciare eccezioni
        repository.deleteById(randomId);
    }

    // --- Update ---
    @Test
    void testUpdateExistingMessage() {
        ChatMessage saved = repository.save(createSampleMessage());
        saved.setContent("Updated content");

        ChatMessage updated = repository.save(saved);

        entityManager.flush();
        entityManager.clear();

        ChatMessage reloaded = repository.findById(updated.getId()).orElseThrow();
        assertThat(reloaded.getContent()).isEqualTo("Updated content");
    }

    // --- Find by todoListId ---
    @Test
    void testFindByTodoListId_multipleMessages() {
        UUID todoListId = UUID.randomUUID();
        ChatMessage m1 = createSampleMessage();
        m1.setTodoListId(todoListId);
        ChatMessage m2 = createSampleMessage();
        m2.setTodoListId(todoListId);
        ChatMessage m3 = createSampleMessage(); // altra todoListId

        repository.save(m1);
        repository.save(m2);
        repository.save(m3);

        List<ChatMessage> messages = repository.findByTodoListId(todoListId);
        assertThat(messages).containsExactlyInAnyOrder(m1, m2);
    }

    @Test
    void testFindByTodoListId_empty() {
        List<ChatMessage> messages = repository.findByTodoListId(UUID.randomUUID());
        assertThat(messages).isEmpty();
    }

    @Test
    void testFindByTodoListId_emptyWhenNoMatchingTodoListId() {
        ChatMessage m1 = createSampleMessage();
        ChatMessage m2 = createSampleMessage();
        repository.save(m1);
        repository.save(m2);

        List<ChatMessage> messages = repository.findByTodoListId(UUID.randomUUID());
        assertThat(messages).isEmpty();
    }

    // --- Edge case: save null ---
    @Test
    void testSaveNullMessage_throwsException() {
        try {
            repository.save(null);
        } catch (Exception e) {
            assertThat(e).isInstanceOf(org.springframework.dao.InvalidDataAccessApiUsageException.class);
        }
    }
}
