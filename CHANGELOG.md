# Changelog

## [2.0.1] - 2026-02-15

### Fixed
- Fixed Control UI sessions failing with `missing scope: operator.read` after HTTP token login when `gateway.controlUi.allowInsecureAuth=true`.
- Added a build-time patch for current OpenClaw `gateway-cli` dist files so insecure Control UI auth keeps declared operator scopes.

## [2.0.0] - 2026-02-15

### Changed
- Restarted the add-on as a minimal gateway-only setup without ingress or HA sidebar panel.
- Reduced add-on options to a single configurable `port` value (default `18789`).
- Simplified runtime startup to direct `openclaw gateway` execution with persistent token handling.
- Enabled `gateway.controlUi.allowInsecureAuth=true` by default to reduce HTTP LAN pairing friction.
- Removed automatic provider/API-key onboarding from add-on startup.

### Kept
- Persistent state in `/share/openclaw/`.
- Home Assistant API bridge via `hassio_api` and Supervisor token environment variables.

## [1.0.0] - 2025-01-30

### Added
- Initial release
- OpenClaw Gateway with Dashboard on port 18789
- Persistent storage in `/share/openclaw/`
- Chromium support for browser automation
- Docker Compose for local development
