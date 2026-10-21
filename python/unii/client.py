import json
import urllib.request
import urllib.error
from typing import List, Dict, Any, Generator, Optional, Union
from .types import (
    ChatMessage,
    ChatChoice,
    Citation,
    ChatCompletionResponse,
    StreamChoice,
    StreamDelta,
    StreamChatCompletionChunk,
    AuthVerificationResponse,
)
from .errors import UniiError, UniiApiError


class UniiClient:
    """Official Unii Python client."""

    def __init__(self, api_key: str, base_url: str = "http://localhost:8080") -> None:
        if not api_key or not isinstance(api_key, str) or not api_key.strip():
            raise UniiError("apiKey is required and must be a non-empty string")
        self.api_key = api_key.strip()
        self.base_url = base_url.rstrip("/")

    def _headers(self, content_type: Optional[str] = "application/json") -> Dict[str, str]:
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "User-Agent": "unii-python-sdk/0.1.0",
        }
        if content_type:
            headers["Content-Type"] = content_type
        return headers

    def verify_auth(self) -> AuthVerificationResponse:
        url = f"{self.base_url}/api/v1/auth/verify"
        req = urllib.request.Request(url, headers=self._headers(None), method="GET")

        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode("utf-8"))
                return AuthVerificationResponse(
                    status=data.get("status", "authenticated"),
                    key_id=data.get("keyId", ""),
                    key_name=data.get("keyName", ""),
                    organization_id=data.get("organizationId", ""),
                    project_id=data.get("projectId", ""),
                )
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8")
            try:
                parsed = json.loads(body)
                msg = parsed.get("message") or parsed.get("error") or str(e)
            except Exception:
                parsed = body
                msg = str(e)
            raise UniiApiError(status=e.code, message=msg, body=parsed)
        except urllib.error.URLError as e:
            raise UniiError(f"Network error: {e.reason}")

    def create_chat_completion(
        self,
        messages: List[Union[ChatMessage, Dict[str, str]]],
        stream: bool = False,
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        project_id: Optional[str] = None,
    ) -> ChatCompletionResponse:
        url = f"{self.base_url}/api/v1/chat/completions"
        if project_id:
            url += f"?projectId={project_id}"

        formatted_messages = []
        for m in messages:
            if isinstance(m, ChatMessage):
                formatted_messages.append({"role": m.role, "content": m.content})
            elif isinstance(m, dict):
                formatted_messages.append({"role": m["role"], "content": m["content"]})
            else:
                raise UniiError("Messages must be ChatMessage instances or dicts with role and content")

        payload: Dict[str, Any] = {
            "messages": formatted_messages,
            "stream": stream,
        }
        if temperature is not None:
            payload["temperature"] = temperature
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens

        req_data = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(url, data=req_data, headers=self._headers("application/json"), method="POST")

        try:
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode("utf-8"))
                choices = []
                for c in data.get("choices", []):
                    msg = c.get("message", {})
                    choices.append(
                        ChatChoice(
                            index=c.get("index", 0),
                            message=ChatMessage(role=msg.get("role", "assistant"), content=msg.get("content", "")),
                            finish_reason=c.get("finish_reason", "stop"),
                        )
                    )

                citation = None
                if data.get("citation"):
                    cit = data["citation"]
                    citation = Citation(
                        document_name=cit.get("documentName", ""),
                        excerpt=cit.get("excerpt", ""),
                        confidence=float(cit.get("confidence", 0.0)),
                    )

                return ChatCompletionResponse(
                    id=data.get("id", ""),
                    object=data.get("object", "chat.completion"),
                    created=data.get("created", 0),
                    model=data.get("model", "unii-rag"),
                    choices=choices,
                    citation=citation,
                )
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8")
            try:
                parsed = json.loads(body)
                msg = parsed.get("message") or parsed.get("error") or str(e)
            except Exception:
                parsed = body
                msg = str(e)
            raise UniiApiError(status=e.code, message=msg, body=parsed)
        except urllib.error.URLError as e:
            raise UniiError(f"Network error: {e.reason}")

    def stream_chat_completion(
        self,
        messages: List[Union[ChatMessage, Dict[str, str]]],
        temperature: Optional[float] = None,
        max_tokens: Optional[int] = None,
        project_id: Optional[str] = None,
    ) -> Generator[StreamChatCompletionChunk, None, None]:
        url = f"{self.base_url}/api/v1/chat/completions?stream=true"
        if project_id:
            url += f"&projectId={project_id}"

        formatted_messages = []
        for m in messages:
            if isinstance(m, ChatMessage):
                formatted_messages.append({"role": m.role, "content": m.content})
            elif isinstance(m, dict):
                formatted_messages.append({"role": m["role"], "content": m["content"]})
            else:
                raise UniiError("Messages must be ChatMessage instances or dicts")

        payload: Dict[str, Any] = {
            "messages": formatted_messages,
            "stream": True,
        }
        if temperature is not None:
            payload["temperature"] = temperature
        if max_tokens is not None:
            payload["max_tokens"] = max_tokens

        req_data = json.dumps(payload).encode("utf-8")
        headers = self._headers("application/json")
        headers["Accept"] = "text/event-stream"
        req = urllib.request.Request(url, data=req_data, headers=headers, method="POST")

        try:
            with urllib.request.urlopen(req) as response:
                for line in response:
                    decoded = line.decode("utf-8").strip()
                    if not decoded or not decoded.startswith("data:"):
                        continue
                    raw_data = decoded[5:].strip()
                    if raw_data == "[DONE]":
                        break
                    try:
                        chunk_dict = json.loads(raw_data)
                        choices = []
                        for c in chunk_dict.get("choices", []):
                            delta_dict = c.get("delta", {})
                            choices.append(
                                StreamChoice(
                                    index=c.get("index", 0),
                                    delta=StreamDelta(
                                        role=delta_dict.get("role"),
                                        content=delta_dict.get("content"),
                                    ),
                                    finish_reason=c.get("finish_reason"),
                                )
                            )
                        yield StreamChatCompletionChunk(
                            id=chunk_dict.get("id", ""),
                            object=chunk_dict.get("object", "chat.completion.chunk"),
                            created=chunk_dict.get("created", 0),
                            model=chunk_dict.get("model", "unii-rag"),
                            choices=choices,
                        )
                    except json.JSONDecodeError:
                        continue
        except urllib.error.HTTPError as e:
            body = e.read().decode("utf-8")
            try:
                parsed = json.loads(body)
                msg = parsed.get("message") or parsed.get("error") or str(e)
            except Exception:
                parsed = body
                msg = str(e)
            raise UniiApiError(status=e.code, message=msg, body=parsed)
        except urllib.error.URLError as e:
            raise UniiError(f"Network error: {e.reason}")
