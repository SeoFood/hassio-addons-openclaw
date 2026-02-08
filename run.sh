#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw
TOKEN_FILE=$DATA_DIR/.gateway-token
CONFIG_FILE=$DATA_DIR/clawdbot.json

# Port is fixed for ingress
PORT=18789

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

# Read trusted proxies from addon options (default: empty)
TRUSTED_PROXIES=$(jq -c '.trusted_proxies // []' /data/options.json)

# Add Home Assistant Supervisor proxy network to trusted proxies
TRUSTED_PROXIES=$(echo "$TRUSTED_PROXIES" | jq '. + ["172.30.32.0/23"]')

# Get ingress path from Supervisor API
INGRESS_ENTRY=""
if [ -n "$SUPERVISOR_TOKEN" ]; then
    INGRESS_ENTRY=$(curl -s http://supervisor/addons/self/info \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" | jq -r '.data.ingress_entry // empty')
    echo "Ingress path: $INGRESS_ENTRY"
fi

# Patch Control UI: inject script to fix WebSocket URL for HA Ingress
# The Control UI constructs ws(s)://location.host without path, which bypasses Ingress.
# This script detects Ingress access and sets the correct gatewayUrl in localStorage.
if [ -n "$INGRESS_ENTRY" ]; then
    GLOBAL_MODULES=$(node -e "console.log(require('path').resolve(process.execPath, '../../lib/node_modules'))" 2>/dev/null)
    UI_HTML="$GLOBAL_MODULES/clawdbot/dist/control-ui/index.html"
    if [ ! -f "$UI_HTML" ]; then
        echo "Warning: Control UI index.html not found at $UI_HTML"
    elif grep -q hassio_ingress "$UI_HTML"; then
        echo "Control UI already patched for Ingress"
    else
        cat > /tmp/patch-ui.js <<'PATCH_SCRIPT'
const fs = require('fs');
const file = process.argv[2];
const html = fs.readFileSync(file, 'utf8');
const fix = [
  '<script>(function(){',
  'if(location.pathname.indexOf("/api/hassio_ingress/")!==0)return;',
  'var parts=location.pathname.split("/");',
  'if(parts.length<4||!parts[3])return;',
  'var base="/"+parts[1]+"/"+parts[2]+"/"+parts[3];',
  'try{',
  'var s=JSON.parse(localStorage.getItem("clawdbot.control.settings.v1")||"{}");',
  'var p=location.protocol==="https:"?"wss":"ws";',
  's.gatewayUrl=p+"://"+location.host+base;',
  'localStorage.setItem("clawdbot.control.settings.v1",JSON.stringify(s));',
  '}catch(e){}',
  '})();</script>',
].join('');
fs.writeFileSync(file, html.replace('</head>', fix + '</head>'));
PATCH_SCRIPT
        node /tmp/patch-ui.js "$UI_HTML" && echo "Patched Control UI: WebSocket URL fix for Ingress injected"
        rm -f /tmp/patch-ui.js
    fi
fi

# Create/update config with trusted proxies
if [ ! -f "$CONFIG_FILE" ]; then
    jq -n --argjson proxies "$TRUSTED_PROXIES" \
        '{gateway: {trustedProxies: $proxies, controlUi: {allowInsecureAuth: true}}}' > "$CONFIG_FILE"
    chown openclaw:openclaw "$CONFIG_FILE"
else
    jq --argjson proxies "$TRUSTED_PROXIES" \
        '.gateway.trustedProxies = $proxies | .gateway.controlUi.allowInsecureAuth = true | del(.gateway.controlUi.basePath)' \
        "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
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
echo "Access via Home Assistant Ingress (Sidebar)"
echo "or direct: http://<container-ip>:$PORT/?token=$GATEWAY_TOKEN"
echo ""

exec su openclaw -c "CLAWDBOT_GATEWAY_TOKEN='$GATEWAY_TOKEN' clawdbot gateway --bind lan --port $PORT --allow-unconfigured"
