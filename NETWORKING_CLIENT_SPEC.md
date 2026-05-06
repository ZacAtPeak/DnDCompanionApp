# Save State Networking Client Spec

This document describes the networking protocol currently implemented by the app backend in `DnDAppSwiftUI/Services/Networking/`.

It reflects the current backend after the delta-protocol migration work:

- protocol version `2`
- Bonjour discovery
- TCP transport
- JSON messages
- 4-byte big-endian length-prefixed framing
- host-authoritative state
- full snapshots for bootstrap and recovery
- deltas for assigned-player command updates

## Scope

- Protocol version: `2`
- Bonjour service type: `_dndapp._tcp`
- Transport: TCP
- Encoding: JSON
- Framing: `[4-byte big-endian length][JSON payload bytes]`
- Date encoding: Unix epoch milliseconds
- Topology: one host, multiple clients

## Transport

Each application message is sent as a single framed payload:

```text
[4-byte big-endian unsigned length][JSON payload]
```

Maximum payload size is `16 MiB`.

Each JSON payload is a `CampaignNetworkEnvelope`.

## Session Model

- The host is authoritative.
- Clients do not send full-state replacements.
- Clients send commands.
- The host validates commands, applies accepted mutations, increments a revision, and emits deltas.
- The host can still send full snapshots, and currently still does so for many host-originated local edits.

## Roles

### Host

- Advertises a Bonjour session.
- Accepts TCP client connections.
- Tracks connected clients by `clientID`.
- Owns canonical session state and revision.
- Assigns player characters to clients.
- Validates and applies assigned-player commands.
- Broadcasts deltas and snapshots.

### Client

- Discovers Bonjour sessions.
- Connects to one host at a time.
- Performs `hello` / `welcome` handshake.
- Requests a snapshot or attempts resume.
- Applies snapshots and deltas in revision order.
- Sends commands only for its assigned player character.

## Envelope

All messages use this envelope:

```json
{
  "schemaVersion": 2,
  "sessionID": "UUID",
  "sentAt": 1778012345678,
  "message": {
    "type": "hello",
    "payload": {}
  }
}
```

Fields:

| Field | Type | Notes |
|---|---|---|
| `schemaVersion` | `Int` | always `2` |
| `sessionID` | `UUID` | may be all-zero pre-session |
| `sentAt` | `Int` | epoch milliseconds |
| `message` | object | tagged union |

### Pre-Session Envelope Rule

Before the client knows the real session ID, it sends:

```text
00000000-0000-0000-0000-000000000000
```

as the envelope `sessionID`.

This is used for:

- client `hello`
- host `welcome`

After `welcome`, all messages should use the real host `sessionID`.

## Discovery

- Service type: `_dndapp._tcp`
- Service name: chosen by the host when hosting starts
- Peer-to-peer discovery is enabled via Apple’s Network framework transport settings

## Connection Lifecycle

Current backend states on the client side are:

- `idle`
- `browsing`
- `connecting`
- `connectedUnsynced(peerName)`
- `syncing(peerName)`
- `ready(peerName)`
- `stale(peerName)`
- `failed(message)`

Meaning:

- `connectedUnsynced`: TCP connected, `hello` sent, waiting to synchronize
- `syncing`: `welcome` received, snapshot/resume in progress
- `ready`: snapshot successfully applied
- `stale`: a delta gap was detected; client requests a fresh snapshot

## Handshake

### Initial Connect

1. Client discovers host and opens TCP connection.
2. Client sends `hello` using zero UUID as envelope `sessionID`.
3. Host validates `hello.protocolVersion`.
4. Host replies with `welcome` using zero UUID as envelope `sessionID`.
5. Client stores the real `sessionID` from `welcome`.
6. Client sends either:
- `resumeSession` if it has a prior `lastAppliedRevision`
- `requestSnapshot` otherwise
7. Host replies with:
- `deltaBatch` if replay is possible
- otherwise `snapshot`

### Resume

If a client reconnects and knows its last applied revision:

1. Client sends `resumeSession`.
2. Host tries to replay retained deltas from `lastAppliedRevision + 1`.
3. If replay is contiguous, host sends `deltaBatch`.
4. If replay is not possible, host sends `snapshot`.

## Message Types

### Session Messages

| Type | Direction | Payload |
|---|---|---|
| `hello` | client -> host | `Hello` |
| `welcome` | host -> client | `CampaignNetworkWelcome` |
| `resumeSession` | client -> host | `CampaignResumeSession` |
| `requestSnapshot` | client -> host | none |
| `ping` | either | `UUID` |
| `pong` | either | `UUID` |
| `error` | host -> client | `CampaignErrorMessage` |

### Replication Messages

| Type | Direction | Payload |
|---|---|---|
| `snapshot` | host -> client | `CampaignNetworkSnapshot` |
| `delta` | host -> client | `CampaignDelta` |
| `deltaBatch` | host -> client | `CampaignDeltaBatch` |
| `assignmentChanged` | host -> client | `PlayerAssignment` |

### Command Messages

| Type | Direction | Payload |
|---|---|---|
| `command` | client -> host | `CampaignCommandEnvelope` |
| `commandAccepted` | host -> client | `CampaignCommandAccepted` |
| `commandRejected` | host -> client | `CampaignCommandRejected` |

## Core Payloads

### `hello`

```json
{
  "clientID": "UUID",
  "displayName": "Player Laptop",
  "protocolVersion": 2,
  "capabilities": {
    "supportsDeltaBatch": true,
    "supportsResume": true
  }
}
```

Notes:

- `protocolVersion` must be `2`.
- If protocol version is unsupported, the host sends `error`.

### `welcome`

```json
{
  "sessionID": "UUID",
  "sessionName": "Tuesday Night Campaign",
  "protocolVersion": 2,
  "currentRevision": 12,
  "heartbeatIntervalMs": 10000,
  "deltaRetentionLimit": 500
}
```

### `resumeSession`

```json
{
  "clientID": "UUID",
  "lastAppliedRevision": 10
}
```

### `error`

```json
{
  "code": "unsupportedProtocol",
  "message": "Client protocolVersion 1 is not supported"
}
```

### `assignmentChanged`

```json
{
  "clientID": "UUID",
  "playerCharacterID": "UUID",
  "assignedByHostAt": 1778012345678
}
```

The client should treat this as authority to send player commands for that player.

## Command Protocol

Clients send only `command` messages for assigned-player updates.

### `command`

```json
{
  "commandID": "UUID",
  "clientID": "UUID",
  "baseRevision": 12,
  "command": {
    "type": "setHitPoints",
    "playerID": "UUID",
    "currentHP": 18,
    "temporaryHP": 3
  }
}
```

Fields:

| Field | Type | Notes |
|---|---|---|
| `commandID` | `UUID` | idempotency key |
| `clientID` | `UUID` | sender |
| `baseRevision` | `Int` | client’s latest applied revision when command was created |
| `command` | tagged union | mutation intent |

### `commandAccepted`

```json
{
  "commandID": "UUID",
  "appliedRevision": 13,
  "appliedAt": 1778012345678
}
```

The accepted receipt means the host applied the command. The client should still treat the following `delta` as the canonical state update.

### `commandRejected`

```json
{
  "commandID": "UUID",
  "rejectedAt": 1778012345678,
  "code": "unassignedClient",
  "reason": "Client has no player assignment"
}
```

## Supported Commands

### `setHitPoints`

```json
{
  "type": "setHitPoints",
  "playerID": "UUID",
  "currentHP": 18,
  "temporaryHP": 3
}
```

Host behavior:

- rejects if client has no assignment
- rejects if command targets a different player than assignment
- clamps `currentHP` to `0...maxHP`
- clamps `temporaryHP` to `>= 0`
- updates matching initiative combatant if present

### `setStatuses`

```json
{
  "type": "setStatuses",
  "playerID": "UUID",
  "statuses": [
    {
      "name": "Blessed",
      "effect": "+d4 to attacks and saves",
      "desc": "Spell effect"
    }
  ]
}
```

Host behavior:

- replaces full player status list
- empty list means no statuses
- updates matching combatant if present

### `setSpellSlot`

```json
{
  "type": "setSpellSlot",
  "playerID": "UUID",
  "level": 3,
  "available": 1
}
```

Host behavior:

- rejects invalid spell slot level outside `1...9`
- if slot exists, clamps availability to `0...max`
- updates matching combatant slot if present

### `setActionUses`

```json
{
  "type": "setActionUses",
  "playerID": "UUID",
  "actionIndex": 0,
  "remainingUses": 1
}
```

Host behavior:

- rejects invalid `actionIndex`
- if action has `maxUses`, clamps `remainingUses` into `0...maxUses`

### `setInventoryEquipped`

```json
{
  "type": "setInventoryEquipped",
  "playerID": "UUID",
  "inventoryItemID": "UUID",
  "isEquipped": true
}
```

Host behavior:

- rejects if the inventory item is not found
- otherwise flips the equip flag

### `submitRoll`

```json
{
  "type": "submitRoll",
  "playerID": "UUID",
  "roll": {
    "type": "Attack",
    "name": "Longsword",
    "roll": 14,
    "modifier": 6,
    "total": 20,
    "timestamp": 1778012345678
  }
}
```

Host behavior:

- prepends roll to roll history

## Snapshot Semantics

Snapshots are authoritative full-state replacements.

Current backend uses snapshots for:

- initial bootstrap
- replay fallback
- stale-client repair
- many host-originated local edits that have not yet been migrated to deltas

### `snapshot`

```json
{
  "schemaVersion": 2,
  "snapshotID": "UUID",
  "snapshotDate": 1778012345678,
  "revision": 12,
  "state": {
    "dataVersion": 7,
    "assignments": [],
    "combatents": [],
    "rollHistory": [],
    "encounters": [],
    "playerInventories": {},
    "monsterInventories": {},
    "npcInventories": {},
    "wikiEntries": [],
    "lootItems": [],
    "spellEntries": [],
    "assets": [],
    "players": [],
    "monsters": [],
    "npcs": []
  }
}
```

Client behavior:

- replace local replicated state with `snapshot.state`
- set `lastAppliedRevision = snapshot.revision`
- clear stale sync state

## Delta Semantics

Deltas are authoritative incremental changes tied to a single host revision.

Current backend emits deltas primarily for assigned-player command updates.

### `delta`

```json
{
  "deltaID": "UUID",
  "revision": 13,
  "previousRevision": 12,
  "createdAt": 1778012345678,
  "originClientID": "UUID",
  "changes": [
    {
      "type": "playerHitPointsChanged",
      "playerID": "UUID",
      "currentHP": 18,
      "temporaryHP": 3
    }
  ]
}
```

Rules:

- each delta represents exactly one new revision
- client may apply it only if `previousRevision == lastAppliedRevision`
- otherwise client must request a new snapshot

### `deltaBatch`

```json
{
  "fromRevision": 11,
  "toRevision": 13,
  "deltas": [ ... ]
}
```

Client behavior:

- apply deltas in ascending revision order
- if any delta has a revision gap, mark state stale and request snapshot

## Implemented Delta Change Types

The backend currently supports these typed changes:

- `assignmentChanged`
- `playerHitPointsChanged`
- `playerStatusesChanged`
- `playerSpellSlotChanged`
- `playerActionUsesChanged`
- `playerInventoryItemEquippedChanged`
- `combatentHitPointsChanged`
- `combatentStatusesChanged`
- `combatentSpellSlotChanged`
- `rollInserted`

### Example `assignmentChanged`

```json
{
  "type": "assignmentChanged",
  "assignment": {
    "clientID": "UUID",
    "playerCharacterID": "UUID",
    "assignedByHostAt": 1778012345678
  }
}
```

### Example `playerHitPointsChanged`

```json
{
  "type": "playerHitPointsChanged",
  "playerID": "UUID",
  "currentHP": 18,
  "temporaryHP": 3
}
```

### Example `playerStatusesChanged`

```json
{
  "type": "playerStatusesChanged",
  "playerID": "UUID",
  "statuses": []
}
```

### Example `playerSpellSlotChanged`

```json
{
  "type": "playerSpellSlotChanged",
  "playerID": "UUID",
  "level": 3,
  "available": 1
}
```

### Example `rollInserted`

```json
{
  "type": "rollInserted",
  "entry": {
    "type": "Attack",
    "name": "Longsword",
    "roll": 14,
    "modifier": 6,
    "total": 20,
    "timestamp": 1778012345678
  },
  "position": "front"
}
```

## Snapshot State DTOs

The snapshot state still uses the existing network DTO family:

- `NetworkStatusCondition`
- `NetworkRollEntry`
- `NetworkSpellSlot`
- `NetworkAttack`
- `NetworkCombatent`
- `NetworkMovementSpeed`
- `NetworkInventoryItem`
- `NetworkAbilityScores`
- `NetworkPlayerState`
- `NetworkMonsterState`
- `NetworkNPCState`
- `NetworkWikiEntry`
- `NetworkLootItem`
- `NetworkItemModifier`
- `NetworkSpellEntry`
- `NetworkAsset`
- `NetworkEncounter`

These shapes are unchanged in spirit from the earlier snapshot-based protocol; the main change is that they now live under `snapshot.state` and snapshots carry a top-level `revision`.

## Validation Rules

Clients should expect rejections for:

- unsupported protocol version
- client has no current player assignment
- command targets a different player than the current assignment
- target player not found
- invalid spell slot level
- invalid action index
- missing inventory item

## Ordering And Consistency

- TCP preserves order per connection.
- The host is the only authority for revisions.
- The client must apply snapshots and deltas only in host-issued order.
- `commandAccepted` is not a substitute for applying the following `delta`.
- The most recent valid host snapshot or contiguous deltas are the source of truth.

## Current Backend Limitations

This is important for client implementers.

- Delta replay exists in memory only.
- Delta retention is bounded to roughly `500` recent revisions.
- If replay is not possible, the host falls back to snapshot.
- Host-originated local edits are still often synchronized via full snapshot rather than typed deltas.
- There is no full reconnect automation beyond explicit resume/snapshot logic.
- There is no authentication beyond local-session trust and host-side player assignment.

## Client Implementation Guidance

- Treat `welcome` as the first message that gives you a real `sessionID`.
- Persist `lastAppliedRevision` for reconnect within a running client session.
- Always be prepared to replace all local state from a fresh `snapshot`.
- Do not attempt client-side merge of peer writes.
- If you detect a gap in revisions, request a snapshot.
- Treat host-issued `assignmentChanged` and snapshot assignments as authoritative.
- Only send player commands for the assigned player.

