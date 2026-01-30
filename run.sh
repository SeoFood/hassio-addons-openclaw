#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
CONFIG_FILE=$DATA_DIR/clawdbot.json

# Read port from addon options
PORT=$(jq -r '.port // 3008' /data/options.json)

# Create persistent directory
mkdir -p $DATA_DIR
chown -R openclaw:openclaw $DATA_DIR

# Symlink für Clawdbot's erwarteten Pfad
mkdir -p /home/openclaw
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

# Create minimal config with trusted proxies if not exists
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
{
  "gateway": {
    "trustedProxies": ["172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8"],
    "controlUi": {
      "allowInsecureAuth": true
    }
  }
}
EOF
    chown openclaw:openclaw "$CONFIG_FILE"
else
    # Update existing config with trusted proxies
    jq '.gateway.trustedProxies = ["172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8"] | .gateway.controlUi.allowInsecureAuth = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    chown openclaw:openclaw "$CONFIG_FILE"
fi

# Environment
export HOME=/home/openclaw
export CLAWDBOT_STATE_DIR=$DATA_DIR
export CLAWDBOT_GATEWAY_TOKEN=$GATEWAY_TOKEN

# Chromium für Puppeteer
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Gateway starten
echo "=========================================="
echo "Gateway Token: $GATEWAY_TOKEN"
echo "=========================================="
echo ""
echo "Open: https://your-domain/?token=$GATEWAY_TOKEN"
echo " or:  http://<ha-ip>:$PORT/?token=$GATEWAY_TOKEN"
echo ""

exec su openclaw -c "CLAWDBOT_GATEWAY_TOKEN='$GATEWAY_TOKEN' clawdbot gateway --bind lan --port $PORT --allow-unconfigured"
