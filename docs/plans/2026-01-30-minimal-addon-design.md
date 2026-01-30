# OpenClaw Add-on v2.0 - Minimal Design

## Ziel

Ein radikal vereinfachtes Home Assistant Add-on für Clawdbot:
- Lifecycle-Management (Start/Restart mit HA)
- Persistenter Speicher
- Keine Token-Manipulation oder automatisches Onboarding

## Entscheidungen

- **Auth:** Wird nicht vom Add-on verwaltet. Benutzer konfiguriert Auth direkt in Clawdbot oder sichert extern ab (z.B. Nginx Proxy Manager)
- **Onboarding:** Einmalig manuell über Terminal
- **Netzwerk:** `host_network: true` für direkten Port-Zugang
- **Standardport:** 3008 (konfigurierbar)

## Dateien

### `config.yaml`

```yaml
name: "OpenClaw"
description: "Personal AI assistant gateway"
version: "2.0.0"
slug: "openclaw"
arch:
  - amd64
init: false
stdin: true
host_network: true
map:
  - share:rw
options:
  port: 3008
schema:
  port: int
```

### `run.sh`

```bash
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
    # Warte, damit Logs sichtbar bleiben
    sleep infinity
fi

# Gateway starten
exec su openclaw -c "clawdbot gateway --bind lan --port $PORT"
```

### `README.md`

```markdown
# OpenClaw Home Assistant Add-on

Personal AI assistant gateway.

## Installation

1. Repository zu Home Assistant hinzufügen
2. OpenClaw Add-on installieren
3. Add-on starten
4. **Einmaliges Setup:** Terminal öffnen und `su openclaw -c "clawdbot onboard"` ausführen
5. Add-on neu starten

## Konfiguration

| Option | Standard | Beschreibung |
|--------|----------|--------------|
| port   | 3008     | Gateway-Port |

Alle weiteren Einstellungen (API-Keys, Auth, Channels) konfigurierst du direkt in Clawdbot beim Onboarding oder später über die Web-UI.

## Zugang

Nach dem Onboarding erreichbar unter:
- `http://<deine-ha-ip>:3008`

Für externen Zugang empfohlen: Reverse Proxy (z.B. Nginx Proxy Manager) mit eigener Auth davor.

## Daten

Persistent in `/share/openclaw/` - bleibt bei Updates erhalten.
```

## Onboarding-Workflow

1. Add-on installieren und starten
2. Logs zeigen Hinweis auf fehlendes Onboarding
3. Terminal öffnen (HA → Add-ons → OpenClaw → Terminal)
4. `su openclaw -c "clawdbot onboard"` ausführen
5. Clawdbot-Setup durchlaufen (API-Keys, Auth, Channels)
6. Add-on neu starten → Gateway läuft

## Nicht enthalten (bewusst)

- Automatisches Onboarding
- Token-Generierung/-Verwaltung
- trusted_proxies Konfiguration
- Ingress/Panel-Integration
