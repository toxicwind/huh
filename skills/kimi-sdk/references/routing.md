# Routing Table

## API Endpoints

| Path | Method | Auth | Timeout | Description |
|------|--------|------|---------|-------------|
| /v1/models | GET | Bearer | 30s | List models |
| /v1/chat/completions | POST | Bearer | 30s | Chat completion |
| /v1/messages | POST | Bearer | 30s | Messages |
| /v1/messages/count_tokens | POST | Bearer | 30s | Token counting |
| /v1/embeddings | POST | Bearer | 30s | Embeddings |
| /v1/search | POST | Bearer | 30s | Web search |
| /v1/fetch | POST | Bearer | 30s | URL fetch |
| /v1/tools | POST | Bearer | 30s | Tool dispatcher |
| /v1/files | POST | Bearer | 30s | File upload |
| /v1/storage | POST | Bearer | 30s | Storage upload |
| /v1/storage/{id} | GET | Bearer | 30s | Storage metadata |

## Error Codes

| Status | Exception | Meaning |
|--------|-----------|---------|
| 401 | AuthenticationError | Invalid API key |
| 402 | PaymentRequiredError | Payment required |
| 403 | QuotaExceededError | Quota exhausted |
| 404 | NotFoundError | Route not found |
| 429 | RateLimitError | Rate limited |
| 5xx | ServerError | Server error |

## Environment Variables

| Variable | Required | Default |
|----------|----------|---------|
| KIMI_API_KEY | Yes | - |
| KIMI_BASE_URL | No | https://agent-gw-dev.dev.kimi.team/coding |
| KIMI_CHAT_ID | No | - |
