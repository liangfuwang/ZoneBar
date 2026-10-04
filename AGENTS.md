# AGENTS.md

> Context file for AI coding agents (pi, Claude Code, etc.) working in this repo.

## Project

- **Name:** ZoneBar
- **Purpose:** macOS menu-bar clock with user-defined time zones (e.g. America/Los_Angeles).
- **Stack:** Swift 5.9 + AppKit, Swift Package Manager (no Xcode project), macOS 13+.

## Layout

- `Sources/ZoneBar/main.swift` — entry; sets `.accessory` activation policy (no Dock icon).
- `Sources/ZoneBar/AppDelegate.swift` — `NSStatusItem`, 1s timer (added in `.common` mode so it ticks while the menu is open), menu building, add/remove zone actions, login-item toggle (`SMAppService`).
- `Sources/ZoneBar/Settings.swift` — UserDefaults-backed settings (zones, primary zone, 24h, seconds, city name).
- `scripts/build-app.sh` — builds release binary and wraps it into `build/ZoneBar.app` (Info.plist with `LSUIElement`, ad-hoc codesign).

- `Resources/AppIcon.icns` — app icon (committed). Regenerate with `swift scripts/make-icon.swift` (drawn in code, edit that script to change the design).

## Commands

- Build + bundle: `./scripts/build-app.sh` (override version: `VERSION=1.2.0 BUILD=3 ./scripts/build-app.sh`)
- Run: `open build/ZoneBar.app` (or `swift run --build-system native`)
- Quit running instance: `pkill ZoneBar`

## Conventions

- Always pass `--build-system native` to `swift build`/`swift run`: the default
  (swift-build/XCBuild) fails here with "Unknown error parsing property list".
- Zones are stored as IANA identifiers; display names for presets live in `presets` in `AppDelegate.swift`.
- Login-item registration only works when run as the bundled `.app`.

## Requirements

- macOS 13+, Xcode Command Line Tools (Swift 5.9+).

## License

MIT, see `LICENSE`.
