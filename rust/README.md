# unii (Rust Crate)

Official Rust client library for Unii platform.

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
unii = "0.1.0"
```

## Quick Start

```rust
use unii::{ChatMessage, ChatCompletionRequest, UniiClient};

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = UniiClient::new(std::env::var("UNII_API_KEY")?)?
        .with_base_url("http://localhost:8080");

    let req = ChatCompletionRequest {
        messages: vec![ChatMessage::user("What is the refund policy?")],
        stream: Some(false),
        temperature: Some(0.7),
        max_tokens: Some(1024),
        project_id: None,
    };

    println!("Client initialized for API: {}", client.base_url());
    Ok(())
}
```
