# OpenClaw Home Assistant Add-on

[OpenClaw](https://openclaw.ai/) als Home Assistant Add-on. Läuft im Host-Netzwerk, sodass die Control-UI inkl. WebSocket direkt erreichbar ist.

## Installation

1. Dieses Repository als Add-on-Repository in Home Assistant hinzufügen
2. **OpenClaw** Add-on installieren
3. Add-on starten
4. Gateway-Token aus dem Add-on-Log kopieren
5. Control-UI öffnen: `http://<deine-ha-ip>:18789/?token=<token>`

## Zugang

| Methode | URL |
|---------|-----|
| Direkt  | `http://<deine-ha-ip>:18789/?token=<token>` |
| Sidebar | Automatisch als Panel "OpenClaw" verfügbar |

Das Gateway-Token wird beim ersten Start generiert und im Add-on-Log angezeigt. Es bleibt bei Neustarts erhalten.

## Konfiguration

| Option | Standard | Beschreibung |
|--------|----------|--------------|
| `trusted_proxies` | `[]` | Zusätzliche Trusted-Proxy-Netzwerke (das HA-Supervisor-Netzwerk wird automatisch hinzugefügt) |

Alle weiteren Einstellungen (API-Keys, Channels, Agents) konfigurierst du direkt in der OpenClaw Control-UI.

## Daten

Persistent in `/share/openclaw/` — bleibt bei Add-on-Updates erhalten.
