# AGENTS.md

Guidance for AI coding agents working in this repository.

## Project overview

`dndappcompanion` is a Flutter application (Dart SDK `^3.11.5`) that acts as a companion app for D&D campaigns. It pairs a host device with one or more client devices over the local network and synchronizes campaign state between them.

The app supports all six Flutter targets: `android/`, `ios/`, `macos/`, `windows/`, `linux/`, and web (via `lib/`). The primary development targets are mobile and desktop.

## Repository layout

- `lib/main.dart` — app entry point and root widget
- `lib/demo_data.dart` — sample data used during development
- `lib/models/` — domain models (monsters, NPCs, player characters, ability scores, attacks, etc.). `models.dart` is the barrel export
- `lib/providers/campaign_state_provider.dart` — campaign state management (host-authoritative)
- `lib/services/networking/` — network client for host/client sync
  - `campaign_network_client.dart` — main client implementation
  - `connection_state.dart` — connection lifecycle states
  - `framing.dart` — 4-byte big-endian length-prefixed message framing
  - `models.dart` — wire-protocol message types
- `lib/widgets/` — reusable UI components (`ability_scores_grid.dart`, `network_session_picker.dart`)
- `test/` — unit and widget tests; networking tests live in `test/services/networking/`
- `NETWORKING_CLIENT_SPEC.md` — protocol v2 spec (Bonjour discovery, TCP, JSON, length-prefixed framing)
- `NETWORKING_DELTA_PROTOCOL_SPEC.md` — delta protocol details
- `CreatureDataSpec.md` — creature/monster data model spec

## Networking protocol (read before touching `lib/services/networking/`)

- Protocol version: `2`
- Bonjour service type: `_dndapp._tcp`
- Transport: TCP, JSON messages, `[4-byte big-endian length][payload]` framing
- Topology: one host, multiple clients; host is authoritative
- Bootstrap and recovery use full snapshots; assigned-player command updates use deltas
- Date encoding: Unix epoch milliseconds

When changing wire format or message types, update `NETWORKING_CLIENT_SPEC.md` and `NETWORKING_DELTA_PROTOCOL_SPEC.md` in the same change. The Swift backend (`DnDAppSwiftUI/Services/Networking/`) is the reference implementation — keep this client compatible.

## Conventions

- Use the existing import style: relative imports inside `lib/`, `package:` imports for third-party deps
- Re-export model types via `lib/models/models.dart`; consumers import the barrel (`as models`)
- Networking imports use a prefix (`as net`) to avoid collisions with model types of the same name
- Lints come from `package:flutter_lints/flutter.yaml` (see `analysis_options.yaml`); fix lint warnings rather than suppressing them
- Keep state mutations flowing through `CampaignStateProvider` — do not mutate model instances from widgets directly

## Dependencies

Runtime: `flutter`, `cupertino_icons`, `uuid`, `nsd` (Bonjour/mDNS service discovery).
Dev: `flutter_test`, `flutter_lints` (see `pubspec.yaml`).

Add a dependency only when needed; prefer the platform/Flutter SDK over a new package.

## Common commands

```bash
flutter pub get          # fetch deps
flutter analyze          # static analysis
flutter test             # run tests
flutter run              # run on the currently selected device
flutter run -d macos     # run on a specific platform
flutter build <target>   # produce a release artifact
```

If `flutter` is not on PATH, the user may have it installed via fvm or a manual SDK — ask before installing.

## Platform notes

- Local network discovery requires platform permissions. Android permissions for this were added in commit `789f723` — check `android/app/src/main/AndroidManifest.xml` before debugging discovery issues there. iOS/macOS need `NSLocalNetworkUsageDescription` and the Bonjour service entry in `Info.plist`.
- The `build/` directory is generated output — do not edit or commit changes there.

## Testing

- Tests live under `test/`, mirroring `lib/` structure where reasonable
- Networking-critical changes (framing, message encoding/decoding) must keep `test/services/networking/framing_test.dart` and `models_test.dart` passing
- Run `flutter test` before declaring a task done

## Things to avoid

- Don't introduce new state-management packages (riverpod/bloc/etc.) without discussion — the project uses a plain provider pattern
- Don't break protocol v2 wire compatibility without bumping the version field and updating both spec docs
- Don't commit `*.bak` files or `build/` artifacts
- Don't add documentation files unless asked; update existing specs in place
