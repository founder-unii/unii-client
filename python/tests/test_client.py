import unittest
from unittest.mock import patch, MagicMock
import io
import json
from unii import UniiClient, UniiError, UniiApiError, ChatMessage


class TestUniiClient(unittest.TestCase):
    def test_constructor_requires_api_key(self):
        with self.assertRaises(UniiError):
            UniiClient("")
        with self.assertRaises(UniiError):
            UniiClient("   ")

    @patch("urllib.request.urlopen")
    def test_verify_auth_success(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "status": "authenticated",
            "keyId": "key-123",
            "keyName": "Backend Key",
            "organizationId": "org-456",
            "projectId": "proj-789"
        }).encode("utf-8")
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        client = UniiClient("test-key")
        res = client.verify_auth()

        self.assertEqual(res.status, "authenticated")
        self.assertEqual(res.key_id, "key-123")
        self.assertEqual(res.key_name, "Backend Key")
        self.assertEqual(res.project_id, "proj-789")

    @patch("urllib.request.urlopen")
    def test_create_chat_completion(self, mock_urlopen):
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "id": "chat-001",
            "object": "chat.completion",
            "created": 1700000000,
            "model": "unii-rag",
            "choices": [
                {
                    "index": 0,
                    "message": {"role": "assistant", "content": "14 days return policy."},
                    "finish_reason": "stop"
                }
            ],
            "citation": {
                "documentName": "terms.pdf",
                "excerpt": "Return within 14 days",
                "confidence": 0.95
            }
        }).encode("utf-8")
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        client = UniiClient("test-key")
        resp = client.create_chat_completion([
            ChatMessage(role="user", content="What is the policy?")
        ])

        self.assertEqual(resp.id, "chat-001")
        self.assertEqual(len(resp.choices), 1)
        self.assertEqual(resp.choices[0].message.content, "14 days return policy.")
        self.assertIsNotNone(resp.citation)
        self.assertEqual(resp.citation.document_name, "terms.pdf")

    @patch("urllib.request.urlopen")
    def test_stream_chat_completion(self, mock_urlopen):
        sse_lines = [
            b'data: {"id":"chat-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"}}]}\n',
            b'data: {"id":"chat-1","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":" world"}}]}\n',
            b'data: [DONE]\n'
        ]
        mock_response = MagicMock()
        mock_response.__iter__.return_value = iter(sse_lines)
        mock_response.__enter__.return_value = mock_response
        mock_urlopen.return_value = mock_response

        client = UniiClient("test-key")
        stream = client.stream_chat_completion([{"role": "user", "content": "Hi"}])
        chunks = list(stream)

        self.assertEqual(len(chunks), 2)
        self.assertEqual(chunks[0].choices[0].delta.content, "Hello")
        self.assertEqual(chunks[1].choices[0].delta.content, " world")


if __name__ == "__main__":
    unittest.main()
