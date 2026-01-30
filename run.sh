#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token

# Create persistent directories
mkdir -p $DATA_DIR

# Fix permissions
chown -R openclaw:openclaw $DATA_DIR

# Create parent directories for symlinks
mkdir -p /home/openclaw

# Symlink state directory to persistent storage
ln -sf $DATA_DIR /home/openclaw/.clawdbot

# Generate or load gateway token
if [ -f "$TOKEN_FILE" ]; then
    GATEWAY_TOKEN=$(cat "$TOKEN_FILE")
else
    # Generate a random token
    GATEWAY_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "$GATEWAY_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    chown openclaw:openclaw "$TOKEN_FILE"
fi

# Environment variables
export HOME=/home/openclaw
export CLAWDBOT_STATE_DIR=$DATA_DIR
export CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN

# Create clawdbot config with trusted proxies (for reverse proxy support)
CONFIG_FILE=$DATA_DIR/clawdbot.json
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << 'CONFIGJSON'
{
  "gateway": {
    "trustedProxies": ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"]
  }
}
CONFIGJSON
    chown openclaw:openclaw "$CONFIG_FILE"
fi

# Chromium settings for headless operation
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
export CHROME_BIN=/usr/bin/chromium-browser

echo "Starting OpenClaw Gateway..."
echo "Data directory: $DATA_DIR"
echo ""
echo "=========================================="
echo "Dashboard URL (with token):"
echo "  http://homeassistant.local:18789/?token=$GATEWAY_TOKEN"
echo ""
echo "Gateway Token: $GATEWAY_TOKEN"
echo "=========================================="
echo ""
echo "Complete setup via the Dashboard (API keys, channels, etc.)"

# Start gateway with dashboard
# --bind lan: Listen on all interfaces (host_network mode)
# --allow-unconfigured: Allow starting without prior configuration (for onboarding)
exec su openclaw -c "CLAWDBOT_GATEWAY_TOKEN='$GATEWAY_TOKEN' clawdbot gateway --bind lan --port 18789 --allow-unconfigured"
