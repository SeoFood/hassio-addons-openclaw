# OpenClaw Home Assistant Add-on

[OpenClaw](https://openclaw.ai/) als Home Assistant Add-on. Läuft im Host-Netzwerk, sodass die Control-UI inkl. WebSocket direkt erreichbar ist.

## Installation

1. Dieses Repository als Add-on-Repository in Home Assistant hinzufügen
2. **OpenClaw** Add-on installieren
3. Add-on starten

## Ersteinrichtung (Onboarding)

Beim ersten Start muss das Onboarding durchgeführt werden. Dabei wählst du deinen AI-Provider und die Auth-Methode (API-Key, OAuth, etc.).

1. Add-on starten — das Log zeigt eine Onboarding-Anleitung
2. **Terminal/SSH Add-on** öffnen und den Onboarding-Wizard starten:
   ```bash
   docker exec -it $(hostname) su openclaw -c "openclaw onboard"
   ```
3. Den Anweisungen folgen: Provider wählen (Anthropic, OpenAI, Google, Ollama, ...) und Auth-Methode konfigurieren
4. Add-on neu starten

Nach dem Onboarding ist die Control-UI voll funktionsfähig.

## Zugang

| Methode | URL |
|---------|-----|
| Direkt  | `http://<deine-ha-ip>:18789/?token=<token>` |
| Sidebar | Automatisch als Panel "OpenClaw" verfügbar |

Das Gateway-Token wird beim ersten Start generiert und im Add-on-Log angezeigt. Es bleibt bei Neustarts erhalten.

## Konfiguration

Provider und Auth-Profile werden beim Onboarding eingerichtet. Channels, Agents und weitere Einstellungen konfigurierst du in der OpenClaw Control-UI.

## Daten

Persistent in `/share/openclaw/` — bleibt bei Add-on-Updates erhalten.
