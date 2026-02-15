# OpenClaw Home Assistant Add-on

Minimal OpenClaw add-on for Home Assistant with direct gateway access (no ingress).

## Installation

1. Add this repository in Home Assistant under Add-on Store -> Repositories.
2. Install the **OpenClaw** add-on.
3. Start the add-on.

## Configuration

Only one option is exposed:

| Option | Default | Description |
|--------|---------|-------------|
| `port` | `18789` | Gateway HTTP/WS port |

## First start and access

On first start, the add-on generates a persistent gateway token and logs it.

- Open: `http://<HA-IP>:<port>/?token=<token>`
- Example: `http://192.168.1.10:18789/?token=...`

The token is stored in `/share/openclaw/.gateway-token` and survives restarts and updates.

## Pairing behavior

This add-on enables `gateway.controlUi.allowInsecureAuth=true` by default to reduce browser pairing friction on plain HTTP LAN access.

- Control-UI pairing friction is reduced.
- Channel pairing (for example WhatsApp QR, Telegram bot setup) still works normally.

## Onboarding

No automatic provider onboarding is done by the add-on.

If OpenClaw is not configured yet, run onboarding manually from a shell in the container:

```bash
su openclaw -c "openclaw onboard"
```

Then restart the add-on.

## Home Assistant API access

The add-on keeps `hassio_api: true` and passes:

- `HA_URL=http://supervisor/core`
- `HA_TOKEN=$SUPERVISOR_TOKEN`

This allows OpenClaw agents/tools to call Home Assistant APIs from inside the add-on container.

## Data persistence

All persistent state lives in `/share/openclaw/`.
