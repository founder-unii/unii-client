import XCTest
@testable import Unii

final class UniiClientTests: XCTestCase {
    func testChatMessageInitialization() {
        let userMsg = ChatMessage.user("Hello Unii")
        XCTAssertEqual(userMsg.role, "user")
        XCTAssertEqual(userMsg.content, "Hello Unii")

        let assistantMsg = ChatMessage.assistant("Hello back")
        XCTAssertEqual(assistantMsg.role, "assistant")
        XCTAssertEqual(assistantMsg.content, "Hello back")
    }

    func testChatCompletionRequestEncoding() throws {
        let req = ChatCompletionRequest(
            messages: [ChatMessage.user("Test question")],
            stream: false,
            temperature: 0.7,
            maxTokens: 512,
            projectId: "proj-1"
        )

        let data = try JSONEncoder().encode(req)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["stream"] as? Bool, false)
        XCTAssertEqual(json?["temperature"] as? Double, 0.7)
        XCTAssertEqual(json?["max_tokens"] as? Int, 512)
        XCTAssertEqual(json?["projectId"] as? String, "proj-1")
    }

    func testChatCompletionResponseDecoding() throws {
        let json = """
        {
            "id": "chatcmpl-swift-test",
            "object": "chat.completion",
            "created": 1700000000,
            "model": "unii-rag",
            "choices": [
                {
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": "This is a grounded answer."
                    },
                    "finish_reason": "stop"
                }
            ],
            "citation": {
                "documentName": "guide.pdf",
                "excerpt": "According to the guide...",
                "confidence": 0.98
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ChatCompletionResponse.self, from: json)
        XCTAssertEqual(response.id, "chatcmpl-swift-test")
        XCTAssertEqual(response.choices.count, 1)
        XCTAssertEqual(response.choices[0].message.content, "This is a grounded answer.")
        XCTAssertNotNil(response.citation)
        XCTAssertEqual(response.citation?.documentName, "guide.pdf")
        XCTAssertEqual(response.citation?.confidence, 0.98)
    }

    func testAuthVerificationResponseDecoding() throws {
        let json = """
        {
            "status": "authenticated",
            "keyId": "k-1",
            "keyName": "admin-key",
            "organizationId": "org-1",
            "projectId": "p-1"
        }
        """.data(using: .utf8)!

        let auth = try JSONDecoder().decode(AuthVerificationResponse.self, from: json)
        XCTAssertEqual(auth.status, "authenticated")
        XCTAssertEqual(auth.keyId, "k-1")
        XCTAssertEqual(auth.projectId, "p-1")
    }
}
