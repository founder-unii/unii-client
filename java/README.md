# unii-java-sdk

Official Java and Kotlin client library for Unii platform.

Compatible with Java 17+ and Kotlin 1.9+. Zero third-party dependencies (uses Java standard library `java.net.http.HttpClient`).

## Maven

```xml
<dependency>
    <groupId>io.github.dev-unii</groupId>
    <artifactId>unii-java-sdk</artifactId>
    <version>0.1.0</version>
</dependency>
```

## Gradle (Kotlin / Groovy)

```kotlin
implementation("io.github.dev-unii:unii-java-sdk:0.1.0")
```

## Usage in Java

```java
import com.malviys.unii.UniiClient;
import com.malviys.unii.model.*;

public class Main {
    public static void main(String[] args) {
        UniiClient client = UniiClient.builder()
            .apiKey(System.getenv("UNII_API_KEY"))
            .baseUrl("http://localhost:8080")
            .build();

        // 1. Verify credentials
        AuthVerificationResponse auth = client.verifyAuth();
        System.out.println("Verified key: " + auth.keyName());

        // 2. Chat completion
        ChatCompletionResponse response = client.createChatCompletion(
            ChatCompletionRequest.builder()
                .messages(ChatMessage.user("What is the return policy?"))
                .build()
        );
        System.out.println(response.choices().get(0).message().content());

        // 3. Stream tokens in real time
        client.streamChatCompletion(
            ChatCompletionRequest.builder()
                .messages(ChatMessage.user("Explain warranty details."))
                .build()
        ).forEach(chunk -> {
            System.out.print(chunk.choices().get(0).delta().content());
        });
    }
}
```

## Usage in Kotlin

```kotlin
import com.malviys.unii.UniiClient
import com.malviys.unii.model.ChatCompletionRequest
import com.malviys.unii.model.ChatMessage

fun main() {
    val client = UniiClient.create(System.getenv("UNII_API_KEY"))

    val auth = client.verifyAuth()
    println("Authenticated: ${auth.keyName}")

    val completion = client.createChatCompletion(
        ChatCompletionRequest.builder()
            .messages(ChatMessage.user("Hello, what is your refund window?"))
            .build()
    )
    println(completion.choices[0].message.content)
}
```
