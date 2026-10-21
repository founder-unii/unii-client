package com.malviys.unii;

import com.malviys.unii.model.ChatMessage;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class UniiClientTest {
    @Test
    void requiresApiKey() {
        assertThrows(NullPointerException.class, () -> UniiClient.create(null));
        assertThrows(IllegalArgumentException.class, () -> UniiClient.create("  "));
    }

    @Test
    void builderConstructsInstance() {
        UniiClient client = UniiClient.builder()
            .apiKey("test-key")
            .baseUrl("http://localhost:8080/")
            .build();
        assertNotNull(client);
    }

    @Test
    void chatMessageHelpersWork() {
        ChatMessage sys = ChatMessage.system("sys");
        assertEquals("system", sys.role());
        assertEquals("sys", sys.content());

        ChatMessage user = ChatMessage.user("hello");
        assertEquals("user", user.role());
        assertEquals("hello", user.content());
    }
}
