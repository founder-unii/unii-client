# @unii/python (unii)

Official Python SDK for Unii conversational AI platform.

## Installation

```bash
pip install unii
```

## Quick Start

```python
from unii import UniiClient

client = UniiClient(api_key="<YOUR_API_KEY>")

# 1. Verify credentials
auth = client.verify_auth()
print(f"Authenticated for project: {auth.project_id}")

# 2. Conversational completion
resp = client.create_chat_completion(
    messages=[{"role": "user", "content": "What is the return policy?"}]
)
print(resp.choices[0].message.content)

# 3. Stream tokens in real time
for chunk in client.stream_chat_completion(
    messages=[{"role": "user", "content": "Explain warranty coverage."}]
):
    print(chunk.choices[0].delta.content or "", end="", flush=True)
```
