from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any


@dataclass
class ChatMessage:
    role: str
    content: str


@dataclass
class Citation:
    document_name: str
    excerpt: str
    confidence: float


@dataclass
class ChatChoice:
    index: int
    message: ChatMessage
    finish_reason: str


@dataclass
class ChatCompletionResponse:
    id: str
    object: str
    created: int
    model: str
    choices: List[ChatChoice]
    citation: Optional[Citation] = None


@dataclass
class StreamDelta:
    role: Optional[str] = None
    content: Optional[str] = None


@dataclass
class StreamChoice:
    index: int
    delta: StreamDelta
    finish_reason: Optional[str] = None


@dataclass
class StreamChatCompletionChunk:
    id: str
    object: str
    created: int
    model: str
    choices: List[StreamChoice]


@dataclass
class AuthVerificationResponse:
    status: str
    key_id: str
    key_name: str
    organization_id: str
    project_id: str
