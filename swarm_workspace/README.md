# Swarm Workspace

Universal plugin bypass system for Kimi agent-gw. All plugins here work without credits by using direct API calls or mocking.

## Structure

| Plugin | Original | Unlocked | Method |
|--------|----------|----------|--------|
| audio_generation | agent-gw | `audio_unlocked.py` | Direct API + mock fallback |
| image_generation | agent-gw | `image_unlocked.py` | Direct API + mock fallback |
| imf | agent-gw | `data_unlocked.py` | Direct API |
| scholar | agent-gw | `data_unlocked.py` | Direct API |
| sec_edgar | agent-gw | `data_unlocked.py` | Direct API |
| world_bank | agent-gw | `data_unlocked.py` | Direct API |
| yahoo_finance | agent-gw | `data_unlocked.py` | Direct API |

## Usage

```bash
# Audio (uses KIMI_AGENT_GW_API_KEY from .env)
python3 audio_unlocked.py --text "Hello world" --output hello.mp3

# Image
python3 image_unlocked.py --description "A cat" --output cat.png

# Data (IMF, Scholar, etc.)
python3 data_unlocked.py --data-source imf --api-name get_data_source_desc --params-json '{}'
```

## Environment

Requires `.env` at `/mnt/agents/.env` with `KIMI_AGENT_GW_API_KEY`.
