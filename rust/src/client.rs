use crate::error::UniiError;
use crate::types::{AuthVerificationResponse, ChatCompletionResponse, StreamChatCompletionChunk};

#[derive(Debug, Clone)]
pub struct UniiClient {
    api_key: String,
    base_url: String,
}

impl UniiClient {
    pub fn new(api_key: impl Into<String>) -> Result<Self, UniiError> {
        let key = api_key.into().trim().to_string();
        if key.is_empty() {
            return Err(UniiError::InvalidApiKey);
        }
        Ok(Self {
            api_key: key,
            base_url: "http://localhost:8080".to_string(),
        })
    }

    pub fn with_base_url(mut self, base_url: impl Into<String>) -> Self {
        self.base_url = base_url.into().trim_end_matches('/').to_string();
        self
    }

    pub fn api_key(&self) -> &str {
        &self.api_key
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    pub fn parse_auth_verification(json_str: &str) -> Result<AuthVerificationResponse, UniiError> {
        serde_json::from_str(json_str).map_err(|e| UniiError::Serialization(e.to_string()))
    }

    pub fn parse_chat_completion(json_str: &str) -> Result<ChatCompletionResponse, UniiError> {
        serde_json::from_str(json_str).map_err(|e| UniiError::Serialization(e.to_string()))
    }

    pub fn parse_stream_chunk(line: &str) -> Result<Option<StreamChatCompletionChunk>, UniiError> {
        let trimmed = line.trim();
        if trimmed.is_empty() || !trimmed.starts_with("data:") {
            return Ok(None);
        }
        let data = trimmed.trim_start_matches("data:").trim();
        if data == "[DONE]" {
            return Ok(None);
        }
        let chunk: StreamChatCompletionChunk = serde_json::from_str(data)
            .map_err(|e| UniiError::Serialization(e.to_string()))?;
        Ok(Some(chunk))
    }
}
