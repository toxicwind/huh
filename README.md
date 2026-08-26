# huh — Portable OSINT & MCP Toolkit

## Structure

```
huh/
├── bin/
│   └── huh-osint          # Main executable (stdlib only)
├── lib/
│   └── huh_mcp.py         # MCP client library
├── docs/
│   └── nsenter_context7.md
├── requirements.txt       # Documentary (no deps required)
└── README.md
```

## Usage

```bash
# Direct execution — zero dependencies
python3 bin/huh-osint

# Or make executable
chmod +x bin/huh-osint
./bin/huh-osint
```

## Working MCPs

| MCP | Status | Key |
|-----|--------|-----|
| Context7 | ✅ Working | `ctx7sk-a95eb8a5-0eb2-4bb4-adff-b4393ed00119` |
| Mintlify | ⚠️ Scope needed | `mint_FSvZZ2bom9qkDegD9kzh99` |
| Exa | ❌ Payment required | — |

## Environment

- Container: Docker, `cap_sys_admin` missing
- Chrome 149: CDP active on port 9222
- GitHub: `toxicwind`, 234 repos
