use std::fmt;

#[derive(Debug)]
pub enum UniiError {
    InvalidApiKey,
    ApiError { status: u16, message: String, body: Option<String> },
    Network(String),
    Serialization(String),
}

impl fmt::Display for UniiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidApiKey => write!(f, "API key is required and cannot be empty"),
            Self::ApiError { status, message, .. } => write!(f, "HTTP {}: {}", status, message),
            Self::Network(msg) => write!(f, "Network error: {}", msg),
            Self::Serialization(msg) => write!(f, "Serialization error: {}", msg),
        }
    }
}

impl std::error::Error for UniiError {}
