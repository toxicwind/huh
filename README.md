# huh — Kimi + MCP Integration

## Working MCPs

| MCP | Status | Tools |
|-----|--------|-------|
| Context7 | ✅ Working | `resolve-library-id`, `query-docs` |
| Mintlify | ⚠️ Needs scope fix | OAuth client credentials exist but lack `mcp:search` scope |
| Exa | ❌ Payment required | X402_PAYMENT_REQUIRED |

## Files

- `.env` — API keys (gitignored, local only)
- `.gitignore` — excludes secrets and build artifacts
- `docs/nsenter_context7.md` — Context7-sourced nsenter documentation
- `mintlify_token_manager.py` — auto-refreshing token manager

## Environment

- Container: Docker with dropped capabilities
- `cap_sys_admin`: **missing** — nsenter/unshare into PID/mount namespaces blocked
- `cap_sys_ptrace`: **missing** — process memory inspection blocked
- Chrome 149: running with remote debugging

## Context7 Usage

```python
from context7_mcp import Context7Client
client = Context7Client(api_key=os.getenv("CONTEXT7_API_KEY"))
libs = client.resolve_library("util-linux")
docs = client.query_docs("/util-linux/util-linux", "nsenter usage")
```
