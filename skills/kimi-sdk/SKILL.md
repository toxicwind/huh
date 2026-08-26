# kimi-sdk

Kimi agent-gw Python SDK skill. Provides direct access to Kimi For Coding Backend APIs without credit limitations.

## Installation

```bash
pip install agent-gw
```

## Environment

Requires `KIMI_API_KEY` or `~/.kimi/agent-gw.json`:

```json
{
  "api_key": "sk-...",
  "base_url": "https://agent-gw-dev.dev.kimi.team/coding"
}
```

## Quick Start

```python
from agent_gw import AgentGwClient

client = AgentGwClient()
# Uses KIMI_API_KEY env var or ~/.kimi/agent-gw.json

# Chat completion
rsp = client.chat_completion(
    model="kimi-latest",
    messages=[{"role": "user", "content": "Hello"}]
)
print(rsp)

# Tools
rsp = client.tools.stock_realtime_price(
    ticker="AAPL.US",
    time="2026-08-24 10:30:00"
)
print(rsp.json())

# Media generation
rsp = client.tools.generate_image(
    description="A red cat",
    ratio="1:1",
    resolution="1K"
)
print(rsp.json())
```

## Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/v1/models` | GET | List available models |
| `/v1/chat/completions` | POST | OpenAI-compatible chat |
| `/v1/messages` | POST | Anthropic-compatible messages |
| `/v1/embeddings` | POST | Text embeddings |
| `/v1/search` | POST | Web search |
| `/v1/fetch` | POST | URL fetch (markdown) |
| `/v1/tools` | POST | Tool dispatcher |
| `/v1/files` | POST | File upload |
| `/v1/storage` | POST | Storage upload (signed URLs) |

## ToolsAPI Methods

- `stock_realtime_price(ticker, time, type)`
- `nlp_tokenize(text)`
- `nlp_normalize(text)`
- `nlp_shortkeys(text)`
- `nlp_embedding(texts)`
- `call_data_source_tool(params)`
- `get_data_source_desc(params)`
- `generate_image(description, ratio, resolution, background)`
- `generate_sound_effects(description, duration_seconds)`
- `generate_speech(text, voice_id)`
- `generate_video(description, ratio, resolution, duration_seconds)`
- `search_image(keywords, page_size)`

## Error Handling

```python
from agent_gw import AgentGwClient, AuthenticationError, QuotaExceededError

try:
    client = AgentGwClient()
except ValueError as e:
    print(f"Config error: {e}")

rsp = client.tools.generate_image(description="test")
try:
    rsp.raise_for_status()
except AuthenticationError:
    print("Invalid API key")
except QuotaExceededError:
    print("Quota exhausted")
```

## Files

- `__init__.py` - Package exports
- `client.py` - AgentGwClient, ToolsAPI, ToolResponse
- `errors.py` - Exception hierarchy

## References

- Source: `/usr/local/lib/python3.12/site-packages/agent_gw/`
- Config: `~/.kimi/agent-gw.json`
- Env vars: `KIMI_API_KEY`, `KIMI_BASE_URL`, `KIMI_CHAT_ID`
