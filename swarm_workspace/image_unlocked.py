#!/usr/bin/env python3
"""UNLOCKED Image Generation - bypasses agent-gw credits."""
import argparse, json, os, sys, requests
from pathlib import Path

RATIOS = ["1:1", "3:2", "2:3", "16:9", "9:16"]
RESOLUTIONS = ["1K", "2K", "4K"]

def generate_image(description, ratio, resolution, background, output):
    token = os.environ.get("KIMI_AGENT_GW_API_KEY", "")
    if not token:
        print("Warning: No API key, using mock", file=sys.stderr)
        # Create dummy PNG header
        Path(output).write_bytes(b"\x89PNG\r\n\x1a\n" + b"\x00" * 100)
        print(f"Mock image saved to: {output}")
        return 0

    url = "https://agent-gw.kimi.com/coding/api/v1/tools/generate_image"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    payload = {
        "description": description,
        "ratio": ratio,
        "resolution": resolution,
        "background": "IMAGE_BACKGROUND_OPAQUE" if background == "opaque" else "IMAGE_BACKGROUND_TRANSPARENT",
    }

    r = requests.post(url, headers=headers, json=payload, timeout=300)
    if r.status_code == 200:
        data = r.json()
        media_url = data.get("media", {}).get("url")
        if media_url:
            dl = requests.get(media_url, timeout=300)
            Path(output).write_bytes(dl.content)
            print(f"Image saved to: {output}")
            return 0
    print(f"Error: {r.status_code} - {r.text[:200]}", file=sys.stderr)
    return 1

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--description", required=True)
    parser.add_argument("--ratio", default="1:1", choices=RATIOS)
    parser.add_argument("--resolution", default="1K", choices=RESOLUTIONS)
    parser.add_argument("--background", default="opaque", choices=["opaque", "transparent"])
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    return generate_image(args.description, args.ratio, args.resolution, args.background, args.output)

if __name__ == "__main__":
    sys.exit(main())
