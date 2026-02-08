#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
CONFIG_FILE=$DATA_DIR/openclaw.json

# Port is fixed for ingress
PORT=18789

# Create persistent directory
mkdir -p $DATA_DIR
chown -R openclaw:openclaw $DATA_DIR

# Symlink für OpenClaw's erwarteten Pfad
mkdir -p /home/openclaw
ln -sf $DATA_DIR /home/openclaw/.openclaw

# Generate or load gateway token
if [ -f "$TOKEN_FILE" ]; then
    GATEWAY_TOKEN=$(cat "$TOKEN_FILE")
else
    GATEWAY_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)
    echo "$GATEWAY_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    chown openclaw:openclaw "$TOKEN_FILE"
fi

# Config erstellen oder Trusted Proxies sicherstellen
if [ ! -f "$CONFIG_FILE" ]; then
    jq -n '{gateway: {trustedProxies: ["172.30.32.0/23"], controlUi: {allowInsecureAuth: true}}}' > "$CONFIG_FILE"
    chown openclaw:openclaw "$CONFIG_FILE"
else
    jq '.gateway.trustedProxies = ["172.30.32.0/23"] | .gateway.controlUi.allowInsecureAuth = true' \
        "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
fi

# Environment
export HOME=/home/openclaw
export OPENCLAW_STATE_DIR=$DATA_DIR
export OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN

# Chromium für Puppeteer
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Onboarding-Check
AUTH_PROFILES=$DATA_DIR/auth-profiles.json
if [ ! -f "$AUTH_PROFILES" ] || [ "$(jq 'length' "$AUTH_PROFILES" 2>/dev/null)" = "0" ]; then
    echo "=========================================="
    echo "Kein Onboarding gefunden!"
    echo "Führe das Onboarding aus:"
    echo ""
    echo "  1. HA Terminal/SSH Addon öffnen"
    echo "  2. docker exec -it \$(hostname) su openclaw -c \"openclaw onboard\""
    echo "  3. Danach dieses Addon neu starten"
    echo "=========================================="
    echo ""
fi

# Gateway starten
echo "=========================================="
echo "Gateway Token: $GATEWAY_TOKEN"
echo "=========================================="
echo ""
echo "Access via Home Assistant Ingress (Sidebar)"
echo "or direct: http://<container-ip>:$PORT/?token=$GATEWAY_TOKEN"
echo ""

exec su openclaw -c "OPENCLAW_GATEWAY_TOKEN='$GATEWAY_TOKEN' openclaw gateway --bind lan --port $PORT --allow-unconfigured"
