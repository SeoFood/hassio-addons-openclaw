#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/share/openclaw"
TOKEN_FILE="${DATA_DIR}/.gateway-token"
CONFIG_FILE="${DATA_DIR}/openclaw.json"
SKILL_SRC_DIR="/opt/ha-skill"
SKILL_DEST_DIR="${DATA_DIR}/skills/homeassistant-addon"
DEFAULT_PORT=18789

read_port() {
    local raw=""
    if [[ -f /data/options.json ]]; then
        raw="$(jq -r '.port // empty' /data/options.json 2>/dev/null || true)"
    fi

    if [[ "${raw}" =~ ^[0-9]+$ ]] && (( raw >= 1 && raw <= 65535 )); then
        echo "${raw}"
        return
    fi

    echo "${DEFAULT_PORT}"
}

ensure_config() {
    if [[ ! -f "${CONFIG_FILE}" ]]; then
        jq -n '{gateway: {mode: "local", controlUi: {allowInsecureAuth: true}}}' > "${CONFIG_FILE}"
        return
    fi

    if ! jq empty "${CONFIG_FILE}" >/dev/null 2>&1; then
        local backup
        backup="${CONFIG_FILE}.broken.$(date +%s)"
        mv "${CONFIG_FILE}" "${backup}"
        echo "Existing openclaw.json was invalid and moved to: ${backup}"
        jq -n '{gateway: {mode: "local", controlUi: {allowInsecureAuth: true}}}' > "${CONFIG_FILE}"
        return
    fi

    local tmp
    tmp="$(mktemp)"
    jq '
        if type == "object" then . else {} end
        | (.gateway //= {})
        | (.gateway.mode //= "local")
        | (.gateway.controlUi //= {})
        | .gateway.controlUi.allowInsecureAuth = true
    ' "${CONFIG_FILE}" > "${tmp}"
    mv "${tmp}" "${CONFIG_FILE}"
}

PORT="$(read_port)"

mkdir -p "${DATA_DIR}" /home/openclaw
ln -sfn "${DATA_DIR}" /home/openclaw/.openclaw

if [[ -f "${TOKEN_FILE}" ]]; then
    GATEWAY_TOKEN="$(cat "${TOKEN_FILE}")"
else
    GATEWAY_TOKEN="$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 32)"
    echo "${GATEWAY_TOKEN}" > "${TOKEN_FILE}"
fi

if [[ -d "${SKILL_SRC_DIR}" ]] && [[ ! -f "${SKILL_DEST_DIR}/SKILL.md" ]]; then
    mkdir -p "$(dirname "${SKILL_DEST_DIR}")"
    cp -R "${SKILL_SRC_DIR}" "${SKILL_DEST_DIR}"
fi

ensure_config

chmod 600 "${TOKEN_FILE}" "${CONFIG_FILE}"
chown -R openclaw:openclaw "${DATA_DIR}"

export HOME="/home/openclaw"
export OPENCLAW_STATE_DIR="${DATA_DIR}"
export OPENCLAW_GATEWAY_TOKEN="${GATEWAY_TOKEN}"
export HA_URL="http://supervisor/core"
if [[ -n "${SUPERVISOR_TOKEN:-}" ]]; then
    export HA_TOKEN="${SUPERVISOR_TOKEN}"
else
    echo "Warning: SUPERVISOR_TOKEN not found. HA API calls from OpenClaw will fail."
fi

export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

echo "=========================================="
echo "OpenClaw Gateway"
echo "Port: ${PORT}"
echo "Token: ${GATEWAY_TOKEN}"
echo "URL: http://<HA-IP>:${PORT}/?token=${GATEWAY_TOKEN}"
echo "=========================================="

exec su -m openclaw -c "openclaw gateway --bind lan --port ${PORT} --allow-unconfigured --token ${GATEWAY_TOKEN}"
