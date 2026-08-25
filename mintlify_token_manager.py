#!/usr/bin/env python3
"""
Mintlify MCP Token Manager for 'huh' project
Auto-refreshes access tokens using client_credentials flow
"""
import os
import json
import time
import urllib.request
import urllib.parse
import ssl

class MintlifyTokenManager:
    def __init__(self):
        self.client_id = os.getenv("MINTLIFY_CLIENT_ID")
        self.client_secret = os.getenv("MINTLIFY_CLIENT_SECRET")
        self.token_url = os.getenv("MINTLIFY_TOKEN_ENDPOINT", "https://mcp.mintlify.com/oauth/token")
        self.scope = os.getenv("MINTLIFY_SCOPE", "mcp:search")
        self._token = None
        self._expires_at = 0

    def _ctx(self):
        c = ssl.create_default_context()
        c.check_hostname = False
        c.verify_mode = ssl.CERT_NONE
        return c

    def refresh(self):
        data = urllib.parse.urlencode({
            "grant_type": "client_credentials",
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "scope": self.scope
        }).encode()

        req = urllib.request.Request(
            self.token_url,
            data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST"
        )

        with urllib.request.urlopen(req, context=self._ctx(), timeout=15) as resp:
            result = json.loads(resp.read().decode())
            self._token = result["access_token"]
            self._expires_at = time.time() + result.get("expires_in", 1209600) - 60
            return self._token

    def get_token(self):
        if not self._token or time.time() >= self._expires_at:
            self.refresh()
        return self._token

    def call_mcp(self, method, params=None):
        token = self.get_token()
        payload = {
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params or {}
        }
        req = urllib.request.Request(
            "https://mcp.mintlify.com",
            data=json.dumps(payload).encode(),
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream"
            },
            method="POST"
        )
        with urllib.request.urlopen(req, context=self._ctx(), timeout=20) as resp:
            return json.loads(resp.read().decode())

if __name__ == "__main__":
    mgr = MintlifyTokenManager()
    print("Token:", mgr.refresh()[:50] + "...")
    print("MCP init:", mgr.call_mcp("initialize", {"protocolVersion": "2025-03-26"}))
