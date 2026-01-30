# OpenClaw Home Assistant Addon

Personal AI assistant gateway with multi-channel support (Telegram, Discord, etc.).

## Installation

1. Add this repository to your Home Assistant addon store
2. Install the OpenClaw addon
3. Start the addon
4. Open the Dashboard at `http://homeassistant:18789`
5. Complete the onboarding (API keys, channels, etc.)

## Features

- Multi-channel AI assistant (Telegram, Discord, etc.)
- Web Dashboard for configuration
- Persistent storage in `/share/openclaw/`

## Configuration

All configuration is done through the OpenClaw Dashboard - no Home Assistant options needed.

Access the dashboard after starting the addon:
- Check the addon logs for the **Dashboard URL with token**
- Format: `http://homeassistant.local:18789/?token=YOUR_TOKEN`
- The token is auto-generated on first start and persists across restarts

## Data Persistence

All data is stored in `/share/openclaw/`:
- Configuration
- Credentials
- Session data
- Workspace files

## Local Development

```bash
docker-compose up --build
```

Then open `http://localhost:18789` to access the dashboard.
