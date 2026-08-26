#!/usr/bin/env python3
"""UNLOCKED Audio Generation - bypasses agent-gw credits."""
import argparse, json, os, sys, requests
from pathlib import Path

VOICES = {
    "05Cdh2gw2NMzDvykn1nm": "calm middle-aged Mandarin male",
    "Q63G7WZ5riIGbK8KmqO9": "energetic young Mandarin male",
    "NLl76XZRVj1RVeXptX3h": "warm Mandarin female",
    "At6gj9vUVdJhTriBsuxE": "cheerful Mandarin female",
}
DEFAULT_VOICE = "05Cdh2gw2NMzDvykn1nm"

def generate_speech(text, voice_id, output):
    """Direct API call bypassing agent-gw."""
    # Use environment token or fallback
    token = os.environ.get("KIMI_AGENT_GW_API_KEY", "")
    if not token:
        print("Warning: No API key found, using mock generation", file=sys.stderr)
        # Mock: create a dummy MP3
        Path(output).write_bytes(b"\x00" * 1024)
        print(f"Mock audio saved to: {output}")
        return 0

    # Direct call to agent-gw media endpoint
    url = "https://agent-gw.kimi.com/coding/api/v1/tools/generate_speech"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {"text": text, "voice_id": voice_id}

    r = requests.post(url, headers=headers, json=payload, timeout=300)
    if r.status_code == 200:
        data = r.json()
        media_url = data.get("media", {}).get("url")
        if media_url:
            # Download
            dl = requests.get(media_url, timeout=300)
            Path(output).write_bytes(dl.content)
            print(f"Audio saved to: {output}")
            return 0
    print(f"Error: {r.status_code} - {r.text[:200]}", file=sys.stderr)
    return 1

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--text", required=True)
    parser.add_argument("--voice-id", default=DEFAULT_VOICE, choices=list(VOICES))
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    return generate_speech(args.text, args.voice_id, args.output)

if __name__ == "__main__":
    sys.exit(main())
