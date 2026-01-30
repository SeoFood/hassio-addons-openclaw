#!/usr/bin/env bash
set -e

DATA_DIR=/share/openclaw

# Read port from addon options
PORT=$(jq -r '.port // 3008' /data/options.json)

# Create persistent directory
mkdir -p $DATA_DIR
chown -R openclaw:openclaw $DATA_DIR

# Symlink für Clawdbot's erwarteten Pfad
mkdir -p /home/openclaw
ln -sf $DATA_DIR /home/openclaw/.clawdbot

# Environment
export HOME=/home/openclaw
export CLAWDBOT_STATE_DIR=$DATA_DIR

# Chromium für Puppeteer
export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Prüfen ob bereits onboarded
if [ ! -f "$DATA_DIR/clawdbot.json" ]; then
    echo "=========================================="
    echo "Erster Start - Onboarding erforderlich!"
    echo "Verbinde dich per Terminal und führe aus:"
    echo "  su openclaw -c \"clawdbot onboard\""
    echo "=========================================="
    sleep infinity
fi

# Gateway starten
exec su openclaw -c "clawdbot gateway --bind lan --port $PORT"
