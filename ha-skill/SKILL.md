---
name: homeassistant-addon
description: Control Home Assistant devices with token-efficient API calls.
---

# Home Assistant Control

## Environment

```bash
$HA_URL    # http://supervisor/core
$HA_TOKEN  # Supervisor token
```

## Rules

- Never call `/api/states` without an entity id.
- For direct actions, call the service without pre-checking state.
- Use `/api/template` for searches to keep responses small.

## Common service calls

```bash
# Turn on a light
curl -sX POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  -d '{"entity_id": "light.bathroom"}' "$HA_URL/api/services/light/turn_on"

# Turn off a switch
curl -sX POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  -d '{"entity_id": "switch.coffee"}' "$HA_URL/api/services/switch/turn_off"

# Toggle with brightness
curl -sX POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  -d '{"entity_id": "light.living_room", "brightness_pct": 50}' "$HA_URL/api/services/light/turn_on"
```

## Find entities by area

```bash
curl -sX POST -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" \
  -d '{"template": "{{ area_entities(\"bathroom\") | select(\"match\", \"light.*\") | list }}"}' "$HA_URL/api/template"
```
