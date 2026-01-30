#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
CONFIG_FILE=$DATA_DIR/clawdbot.json
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

# Chromium settings for headless operation
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
export CHROME_BIN=/usr/bin/chromium-browser

# First-time onboarding (skip auth, user configures via dashboard later)
if [ ! -f "$ONBOARD_MARKER" ]; then
    echo "First start - running initial onboarding..."
    su openclaw -c "clawdbot onboard --non-interactive --accept-risk --auth-choice skip --skip-channels --skip-skills --skip-health --skip-ui --gateway-bind lan --gateway-port 18789" || true
    touch "$ONBOARD_MARKER"
    chown openclaw:openclaw "$ONBOARD_MARKER"
fi

# Update config with trusted proxies (merge with existing config)
if [ -f "$CONFIG_FILE" ]; then
    # Add trustedProxies to existing config using jq if available, otherwise Python
    if command -v jq &> /dev/null; then
        jq '.gateway.trustedProxies = ["192.168.199.20", "172.18.0.1", "172.17.0.1", "172.30.32.1", "127.0.0.1"] | .gateway.bind = "lan"' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    else
        python3 -c "
import json
with open('$CONFIG_FILE', 'r') as f:
    cfg = json.load(f)
cfg.setdefault('gateway', {})
cfg['gateway']['trustedProxies'] = ['192.168.199.20', '172.18.0.1', '172.17.0.1', '172.30.32.1', '127.0.0.1']
cfg['gateway']['bind'] = 'lan'
with open('$CONFIG_FILE', 'w') as f:
    json.dump(cfg, f, indent=2)
"
    fi
    chown openclaw:openclaw "$CONFIG_FILE"
fi

echo "Starting OpenClaw Gateway..."
echo "Data directory: $DATA_DIR"
echo ""
echo "=========================================="
echo "Gateway Token: $GATEWAY_TOKEN"
echo "=========================================="
echo ""
echo "Access via Home Assistant sidebar or direct URL"
echo "Complete setup via the Dashboard (API keys, channels, etc.)"

# Start gateway with dashboard
exec su openclaw -c "CLAWDBOT_GATEWAY_TOKEN='$GATEWAY_TOKEN' clawdbot gateway --bind lan --port 18789 --allow-unconfigured"
