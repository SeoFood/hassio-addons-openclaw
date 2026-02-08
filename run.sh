#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
CONFIG_FILE=$DATA_DIR/openclaw.json
AUTH_PROFILES=$DATA_DIR/auth-profiles.json
CONFIG_HASH_FILE=$DATA_DIR/.addon-config-hash

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

# Onboarding via Addon-Optionen
PROVIDER=$(jq -r '.provider // ""' /data/options.json)
API_KEY=$(jq -r '.api_key // ""' /data/options.json)

if [ -n "$PROVIDER" ] && [ -n "$API_KEY" ]; then
    CURRENT_HASH=$(echo -n "${PROVIDER}:${API_KEY}" | sha256sum | cut -d' ' -f1)
    SAVED_HASH=""
    if [ -f "$CONFIG_HASH_FILE" ]; then
        SAVED_HASH=$(cat "$CONFIG_HASH_FILE")
    fi

    if [ "$CURRENT_HASH" != "$SAVED_HASH" ] || [ ! -f "$AUTH_PROFILES" ]; then
        echo "=========================================="
        echo "Onboarding wird ausgeführt (Provider: $PROVIDER)..."
        echo "=========================================="
        if su openclaw -c "OPENCLAW_STATE_DIR='$DATA_DIR' openclaw onboard \
            --non-interactive --auth-choice apiKey \
            --token-provider '$PROVIDER' --token '$API_KEY'"; then
            echo "$CURRENT_HASH" > "$CONFIG_HASH_FILE"
            chmod 600 "$CONFIG_HASH_FILE"
            chown openclaw:openclaw "$CONFIG_HASH_FILE"
            echo "Onboarding erfolgreich abgeschlossen."
        else
            echo "=========================================="
            echo "FEHLER: Onboarding fehlgeschlagen!"
            echo "Bitte Provider und API-Key in den Addon-Optionen prüfen."
            echo "=========================================="
            exit 1
        fi
    else
        echo "Onboarding bereits konfiguriert (Provider: $PROVIDER)."
    fi
elif [ ! -f "$AUTH_PROFILES" ] || [ "$(jq 'length' "$AUTH_PROFILES" 2>/dev/null)" = "0" ]; then
    echo "=========================================="
    echo "Kein Onboarding gefunden!"
    echo ""
    echo "Option A (empfohlen): Provider und API-Key"
    echo "  in den Addon-Optionen setzen und neu starten."
    echo ""
    echo "Option B (für OAuth etc.):"
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
