use unii::{ChatMessage, UniiClient, UniiError};

#[test]
fn test_client_requires_api_key() {
    assert!(matches!(UniiClient::new(""), Err(UniiError::InvalidApiKey)));
    assert!(matches!(UniiClient::new("   "), Err(UniiError::InvalidApiKey)));
    assert!(UniiClient::new("valid-key").is_ok());
}

#[test]
fn test_client_custom_base_url() {
    let client = UniiClient::new("valid-key")
        .unwrap()
        .with_base_url("http://api.unii.dev/");
    assert_eq!(client.base_url(), "http://api.unii.dev");
    assert_eq!(client.api_key(), "valid-key");
}

#[test]
fn test_chat_message_helpers() {
    let msg = ChatMessage::user("Hello");
    assert_eq!(msg.role, "user");
    assert_eq!(msg.content, "Hello");
}

#[test]
fn test_parse_auth_verification() {
    let json = r#"{"status":"authenticated","keyId":"k1","keyName":"Backend","organizationId":"o1","projectId":"p1"}"#;
    let auth = UniiClient::parse_auth_verification(json).unwrap();
    assert_eq!(auth.status, "authenticated");
    assert_eq!(auth.key_name, "Backend");
    assert_eq!(auth.project_id, "p1");
}
