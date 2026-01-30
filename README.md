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
