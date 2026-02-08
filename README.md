# OpenClaw Home Assistant Add-on

[OpenClaw](https://openclaw.ai/) als Home Assistant Add-on. Läuft im Host-Netzwerk, sodass die Control-UI inkl. WebSocket direkt erreichbar ist.

## Installation

1. Dieses Repository als Add-on-Repository in Home Assistant hinzufügen
2. **OpenClaw** Add-on installieren
3. Add-on starten

## Ersteinrichtung (Onboarding)

### Option A: Über Addon-Optionen (empfohlen)

1. Add-on **Konfiguration** öffnen
2. **Provider** auswählen (Anthropic, OpenAI, Google, Ollama, OpenRouter)
3. **API-Key** eingeben
4. Add-on starten — das Onboarding läuft automatisch

Bei Änderung von Provider oder API-Key einfach die Optionen anpassen und das Add-on neu starten.

### Option B: Manuell via Terminal (für OAuth etc.)

1. Add-on starten
2. **Terminal/SSH Add-on** öffnen und den Onboarding-Wizard starten:
   ```bash
   docker exec -it $(hostname) su openclaw -c "openclaw onboard"
   ```
3. Den Anweisungen folgen und Add-on neu starten

Nach dem Onboarding ist die Control-UI voll funktionsfähig.

## Zugang

| Methode | URL |
|---------|-----|
| Direkt  | `http://<deine-ha-ip>:18789/?token=<token>` |
| Sidebar | Automatisch als Panel "OpenClaw" verfügbar |

Das Gateway-Token wird beim ersten Start generiert und im Add-on-Log angezeigt. Es bleibt bei Neustarts erhalten.

## Konfiguration

| Option | Beschreibung |
|--------|-------------|
| `provider` | AI-Provider (anthropic, openai, google, ollama, openrouter) |
| `api_key` | API-Key des Providers (wird maskiert angezeigt) |

Beide Optionen sind optional. Ohne sie muss das Onboarding manuell via Terminal durchgeführt werden.

Channels, Agents und weitere Einstellungen konfigurierst du in der OpenClaw Control-UI.

## Daten

Persistent in `/share/openclaw/` — bleibt bei Add-on-Updates erhalten.
