"""huh_mcp — MCP client implementations for huh project"""
import json
import ssl
import urllib.request

def get_ctx():
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return ctx

class Context7MCP:
    URL = "https://mcp.context7.com/mcp"
    KEY = "ctx7sk-a95eb8a5-0eb2-4bb4-adff-b4393ed00119"

    @classmethod
    def call(cls, method, params):
        payload = json.dumps({"jsonrpc": "2.0", "id": 1, "method": method, "params": params}).encode()
        req = urllib.request.Request(
            cls.URL, data=payload,
            headers={
                "Authorization": f"Bearer {cls.KEY}",
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream"
            },
            method="POST"
        )
        with urllib.request.urlopen(req, context=get_ctx(), timeout=20) as resp:
            body = resp.read().decode()
            for line in body.split("
"):
                if line.startswith("data:"):
                    return json.loads(line[5:].strip())
            return {}
