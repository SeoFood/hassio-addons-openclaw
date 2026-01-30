#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
ONBOARD_MARKER=$DATA_DIR/.onboarded

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
    GATEWAY_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "$GATEWAY_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    chown openclaw:openclaw "$TOKEN_FILE"
fi

# Environment variables
export HOME=/home/openclaw
export CLAWDBOT_STATE_DIR=$DATA_DIR
export CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN

# Chromium settings for headless operation
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
export CHROME_BIN=/usr/bin/chromium-browser

# First-time onboarding
if [ ! -f "$ONBOARD_MARKER" ]; then
    echo "First start - running initial onboarding..."
    su openclaw -c "clawdbot onboard --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-health --skip-ui --gateway-bind lan --gateway-port 3000" || true
    touch "$ONBOARD_MARKER"
    chown openclaw:openclaw "$ONBOARD_MARKER"
fi

echo "Starting OpenClaw Gateway..."
echo "Data directory: $DATA_DIR"
echo ""
echo "=========================================="
echo "Gateway Token: $GATEWAY_TOKEN"
echo "=========================================="
echo ""
echo "Access: http://<your-homeassistant-ip>:3000"
echo ""

# Start gateway
exec su openclaw -c "CLAWDBOT_GATEWAY_TOKEN='$GATEWAY_TOKEN' clawdbot gateway --bind lan --port 3000"
