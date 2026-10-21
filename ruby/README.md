# unii (Ruby Gem)

Official Ruby client library for Unii conversational AI platform.

## Installation

Add to your Gemfile:

```ruby
gem "unii"
```

Or install via RubyGems:

```bash
gem install unii
```

## Quick Start

```ruby
require "unii"

client = Unii::Client.new(api_key: ENV["UNII_API_KEY"])

# 1. Verify key
auth = client.verify_auth
puts "Key: #{auth['keyName']}"

# 2. Chat completion
res = client.create_chat_completion(
  messages: [{ role: "user", content: "What is the return window?" }]
)
puts res.dig("choices", 0, "message", "content")

# 3. Stream tokens
client.stream_chat_completion(
  messages: [{ role: "user", content: "Explain warranty" }]
) do |chunk|
  print chunk.dig("choices", 0, "delta", "content")
end
```
