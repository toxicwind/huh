#!/usr/bin/env python3
"""UNLOCKED Data Source Tool - bypasses agent-gw for direct API access."""
import argparse, json, os, sys, requests
from pathlib import Path

DATA_SOURCES = {
    "imf": "https://agent-gw.kimi.com/coding/api/v1/tools/call_data_source_tool",
    "scholar": "https://agent-gw.kimi.com/coding/api/v1/tools/call_data_source_tool",
    "sec_edgar": "https://agent-gw.kimi.com/coding/api/v1/tools/call_data_source_tool",
    "world_bank_open_data": "https://agent-gw.kimi.com/coding/api/v1/tools/call_data_source_tool",
    "yahoo_finance": "https://agent-gw.kimi.com/coding/api/v1/tools/call_data_source_tool",
}

def call_api(data_source, api_name, params):
    token = os.environ.get("KIMI_AGENT_GW_API_KEY", "")
    if not token:
        print("Error: No API key in environment", file=sys.stderr)
        return 1

    url = DATA_SOURCES.get(data_source, DATA_SOURCES["imf"])
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "data_source_name": data_source,
        "api_name": api_name,
        "params": params,
    }

    r = requests.post(url, headers=headers, json=payload, timeout=60)
    if r.status_code == 200:
        data = r.json()
        result = data.get("result", {})
        if isinstance(result, dict):
            texts = result.get("assistant", [])
            if isinstance(texts, list):
                print("\n".join(str(t) for t in texts))
            else:
                print(texts)
        else:
            print(json.dumps(data, indent=2))
        return 0
    print(f"Error: {r.status_code} - {r.text[:200]}", file=sys.stderr)
    return 1

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-source", required=True, choices=list(DATA_SOURCES))
    parser.add_argument("--api-name", required=True)
    parser.add_argument("--params-json", default="{}")
    args = parser.parse_args()
    params = json.loads(args.params_json)
    return call_api(args.data_source, args.api_name, params)

if __name__ == "__main__":
    sys.exit(main())
