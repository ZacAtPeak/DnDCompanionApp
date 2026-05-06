# Save State Delta Networking Spec

This document defines a concrete replacement for the current snapshot-heavy networking backend.

It is intended for implementation in this repository and for external client implementers who need a stable target protocol. It assumes the existing transport choices remain in place:

- Bonjour discovery
- TCP transport
- JSON payloads
- 4-byte big-endian length-prefixed framing

This spec replaces “broadcast full snapshot after every accepted change” with a server-authoritative command-and-delta model, while retaining full snapshots for initial sync and recovery.

## Goals

- Keep the host as the only authoritative writer of canonical campaign state.
- Let multiple clients send updates concurrently without client-side merge logic.
- Replace steady-state full snapshots with ordered delta replication.
- Keep snapshots for join, reconnect, and recovery from missed deltas.
- Add explicit revisioning, replay, and idempotency.
- Make the protocol easier to reason about than the current mix of commands plus full-state replacement.

## Non-Goals

- End-to-end encryption
- Authentication beyond local-session trust
- Cross-session persistence protocol
- WAN or internet relay support
- CRDT-style peer-to-peer conflict resolution

## Core Design

The protocol has three layers:

1. Session layer
- discovery
- hello / welcome
- resume
- ping / pong
- disconnect / stale handling

2. Command layer, client -> host
- clients send intent
- host validates and applies
- host returns ack or reject

3. Replication layer, host -> clients
- full snapshot for bootstrap or repair
- ordered deltas for normal operation

The host processes commands serially and emits deltas in revision order. Clients do not merge peer writes. Clients only apply host-issued snapshots and deltas.

## Terms

| Term | Meaning |
|---|---|
| `sessionID` | UUID for one hosted campaign networking session |
| `clientID` | UUID chosen by a client instance |
| `revision` | Monotonic host-issued `Int64` for authoritative state changes |
| `commandID` | UUID chosen by the sender for idempotency |
| `deltaID` | UUID for a specific emitted delta |
| `baseRevision` | Revision the sender believes it is building from |
| `lastAppliedRevision` | Latest revision a client has successfully applied |

## Authoritative State Model

The host owns canonical session state. Clients never send raw state replacement objects.

Clients may send:

- commands
- resume requests
- snapshot requests
- ping

Clients may receive:

- welcome
- assignment changes
- command receipts
- deltas
- snapshots
- ping / pong
- errors

## Transport

No transport change is required for v2.

- Bonjour service type remains `_dndapp._tcp`
- Payload encoding remains JSON
- Date encoding remains epoch milliseconds
- Framing remains `[4-byte big-endian length][JSON payload]`
- Maximum frame payload remains `16 MiB`

## Protocol Version

Introduce protocol version `2`.

`hello.protocolVersion` must be validated by the host.

Host behavior:

- if supported, reply with `welcome`
- if unsupported, reply with `error` and close or ignore the connection

## Session Handshake

This replaces the current bootstrap deadlock.

### Client Connect Flow

1. Client opens TCP connection.
2. Client immediately sends `hello` without waiting for a known `sessionID`.
3. Host registers the client connection.
4. Host replies with `welcome`.
5. Client sends either:
- `resumeSession`, if it has prior state for this `sessionID`
- `requestSnapshot`, if it has no state
6. Host responds with:
- `snapshot` if client needs bootstrap or recovery
- or `deltaReplay` / live deltas if resume is possible

### Envelope Rule

To avoid the current deadlock, `hello` and `welcome` are allowed before session synchronization.

Two acceptable implementation choices:

1. Keep `sessionID` at envelope level, but allow a placeholder all-zero UUID for pre-session messages.
2. Move `sessionID` out of the envelope and into message payloads where needed.

For the least invasive migration, use option 1:

- pre-session messages use `00000000-0000-0000-0000-000000000000`
- after `welcome`, all messages use the real `sessionID`

## Envelope Schema

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
| `schemaVersion` | `Int` | protocol schema version, now `2` |
| `sessionID` | `UUID` | zero UUID allowed only for pre-session `hello` and `welcome` |
| `sentAt` | `Int` | epoch milliseconds |
| `message` | object | tagged union |

## Message Types

### Session Messages

| Type | Direction | Purpose |
|---|---|---|
| `hello` | client -> host | introduce client |
| `welcome` | host -> client | accept client and declare session |
| `resumeSession` | client -> host | request replay from a known revision |
| `requestSnapshot` | client -> host | request full state |
| `ping` | either | liveness |
| `pong` | either | liveness response |
| `error` | host -> client | non-command protocol error |

### Command Messages

| Type | Direction | Purpose |
|---|---|---|
| `command` | client -> host | request a mutation |
| `commandAccepted` | host -> client | accepted and applied |
| `commandRejected` | host -> client | rejected and not applied |

### Replication Messages

| Type | Direction | Purpose |
|---|---|---|
| `snapshot` | host -> client | authoritative full state |
| `delta` | host -> client | authoritative state changes for exactly one revision |
| `deltaBatch` | host -> client | optional replay optimization |
| `assignmentChanged` | host -> client | direct assignment notice, also present in snapshot/delta |

## Message Schemas

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

- `clientID` should remain stable for the life of the running client session.
- `capabilities` is optional but useful for forward compatibility.

### `welcome`

```json
{
  "sessionID": "UUID",
  "sessionName": "Tuesday Night Campaign",
  "protocolVersion": 2,
  "currentRevision": 152,
  "heartbeatIntervalMs": 10000,
  "deltaRetentionLimit": 500
}
```

Notes:

- `currentRevision` is the host revision at handshake time.
- `deltaRetentionLimit` describes the approximate replay window, not a hard guarantee.

### `resumeSession`

```json
{
  "clientID": "UUID",
  "lastAppliedRevision": 147
}
```

Host behavior:

- if `147` is still in replay range, send deltas `148...current`
- otherwise send a fresh snapshot

### `requestSnapshot`

No payload.

### `ping`

```json
"UUID"
```

### `pong`

```json
"UUID"
```

### `error`

```json
{
  "code": "unsupportedProtocol",
  "message": "Client protocolVersion 1 is not supported"
}
```

## Command Layer

Clients send only commands. Commands represent intent, not arbitrary state replacement.

### `command`

```json
{
  "commandID": "UUID",
  "clientID": "UUID",
  "baseRevision": 152,
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
| `clientID` | `UUID` | sender identity |
| `baseRevision` | `Int64` | sender’s local revision when command was created |
| `command` | tagged union | domain mutation intent |

### `commandAccepted`

```json
{
  "commandID": "UUID",
  "appliedRevision": 153,
  "appliedAt": 1778012345678
}
```

Notes:

- `commandAccepted` acknowledges acceptance only.
- The canonical content change arrives through `delta`.

### `commandRejected`

```json
{
  "commandID": "UUID",
  "rejectedAt": 1778012345678,
  "reason": "Client has no player assignment",
  "code": "unassignedClient"
}
```

## Command Schemas

The initial command set should map directly onto the current backend capabilities.

### `setHitPoints`

```json
{
  "type": "setHitPoints",
  "playerID": "UUID",
  "currentHP": 18,
  "temporaryHP": 3
}
```

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

### `setSpellSlot`

```json
{
  "type": "setSpellSlot",
  "playerID": "UUID",
  "level": 3,
  "available": 1
}
```

### `setActionUses`

```json
{
  "type": "setActionUses",
  "playerID": "UUID",
  "actionIndex": 0,
  "remainingUses": 1
}
```

### `setInventoryEquipped`

```json
{
  "type": "setInventoryEquipped",
  "playerID": "UUID",
  "inventoryItemID": "UUID",
  "isEquipped": true
}
```

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

## Replication Layer

The host emits one authoritative revision at a time.

For each accepted mutation:

1. host validates command
2. host mutates canonical state
3. host increments `currentRevision`
4. host creates one `delta` for that revision
5. host broadcasts the `delta`
6. host sends `commandAccepted` to the originating client

The ordering of steps 5 and 6 may be swapped, but clients must treat the `delta` as the source of truth.

### `snapshot`

Snapshots remain the bootstrap and repair mechanism.

```json
{
  "snapshotID": "UUID",
  "revision": 152,
  "snapshotDate": 1778012345678,
  "state": {}
}
```

Rules:

- snapshot state fully replaces local replicated state
- after applying snapshot, client sets `lastAppliedRevision = revision`
- any queued older deltas must be discarded

### `delta`

```json
{
  "deltaID": "UUID",
  "revision": 153,
  "previousRevision": 152,
  "createdAt": 1778012345678,
  "originClientID": "UUID",
  "changes": [
    {
      "type": "playerHitPointsChanged",
      "playerID": "UUID",
      "currentHP": 18,
      "temporaryHP": 3
    },
    {
      "type": "combatentHitPointsChanged",
      "combatentID": "UUID",
      "currentHP": 18,
      "temporaryHP": 3
    }
  ]
}
```

Rules:

- each `delta` corresponds to exactly one host revision
- client may apply it only if `previousRevision == lastAppliedRevision`
- otherwise client must request snapshot or replay

### `deltaBatch`

Optional optimization for replay:

```json
{
  "fromRevision": 148,
  "toRevision": 152,
  "deltas": [ ... ]
}
```

Rules:

- only valid for contiguous deltas
- equivalent to applying each delta in order

## Delta Change Types

Use typed domain changes, not generic JSON Patch paths.

This keeps the protocol explicit, safer to evolve, and easier to validate in Swift.

### Initial Change Set

| Change Type | Purpose |
|---|---|
| `assignmentChanged` | client/player assignment updated |
| `playerHitPointsChanged` | player HP or temp HP changed |
| `playerStatusesChanged` | player statuses replaced |
| `playerSpellSlotChanged` | one spell slot level changed |
| `playerActionUsesChanged` | one action usage count changed |
| `playerInventoryItemEquippedChanged` | one item equip flag changed |
| `combatentHitPointsChanged` | initiative combatant HP changed |
| `combatentStatusesChanged` | initiative combatant statuses changed |
| `combatentSpellSlotChanged` | initiative combatant slot changed |
| `rollInserted` | one roll appended/prepended to history |
| `rollHistoryCleared` | roll history reset |
| `combatentsReplaced` | fallback for complex tracker reorder/add/remove |
| `encountersReplaced` | fallback for encounter collection changes |
| `wikiEntriesReplaced` | fallback for wiki changes |
| `lootItemsReplaced` | fallback for loot changes |
| `spellEntriesReplaced` | fallback for spell changes |
| `assetsReplaced` | fallback for asset changes |

The “replaced” changes are deliberate transitional escape hatches. They allow incremental adoption of deltas before every domain has fine-grained change types.

### Example Typed Changes

#### `assignmentChanged`

```json
{
  "type": "assignmentChanged",
  "clientID": "UUID",
  "playerCharacterID": "UUID",
  "assignedByHostAt": 1778012345678
}
```

#### `playerHitPointsChanged`

```json
{
  "type": "playerHitPointsChanged",
  "playerID": "UUID",
  "currentHP": 18,
  "temporaryHP": 3
}
```

#### `playerStatusesChanged`

```json
{
  "type": "playerStatusesChanged",
  "playerID": "UUID",
  "statuses": []
}
```

#### `playerSpellSlotChanged`

```json
{
  "type": "playerSpellSlotChanged",
  "playerID": "UUID",
  "level": 3,
  "available": 1
}
```

#### `rollInserted`

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

#### `combatentsReplaced`

```json
{
  "type": "combatentsReplaced",
  "combatents": [ ... ]
}
```

This is a deliberate migration fallback for add/remove/reorder logic until the tracker has dedicated change types like `combatentAdded`, `combatentRemoved`, `turnAdvanced`, and `combatentsReordered`.

## Snapshot State Shape

The snapshot state should remain close to the current `CampaignNetworkSnapshot`, but it must now include a top-level authoritative revision.

```json
{
  "snapshotID": "UUID",
  "revision": 152,
  "snapshotDate": 1778012345678,
  "state": {
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

Recommendation:

- keep existing DTOs where possible
- rename the current snapshot payload container to something like `CampaignReplicatedState`
- use it inside `snapshot.state`

## Validation Rules

The host must validate commands before mutation.

### Required Validation

- `clientID` belongs to the current TCP connection
- client is assigned to the target player if command is player-scoped
- command targets an existing entity
- command payload values are within valid ranges
- `protocolVersion` is supported
- `sessionID` matches the active session after handshake

### Recommended Validation

- reject duplicate `commandID` if already applied or rejected recently
- optionally compare `baseRevision` against current revision for commands that should fail on stale state
- reject malformed or future-only command variants

### Current Domain Rules To Preserve

- HP clamps to `0...maxHP`
- temp HP clamps to `>= 0`
- spell slot level must be `1...9`
- spell slot availability clamps to `0...max`
- action index must exist
- action uses clamp to `0...maxUses`
- inventory item must exist

## Idempotency

The host must keep a recent command ledger per client.

Suggested structure:

- key: `(clientID, commandID)`
- value: previously emitted `commandAccepted` or `commandRejected`

Suggested retention:

- in-memory LRU cache of last 500 to 2000 commands per client

Behavior:

- if duplicate command arrives, do not reapply it
- resend the prior receipt

## Replay And Recovery

The host should keep a bounded contiguous delta log.

Suggested structure:

- append-only in-memory ring buffer of recent deltas
- indexed by `revision`

Suggested retention:

- last 500 revisions initially

Resume behavior:

- if client requests resume from `lastAppliedRevision`
- and host still has all later deltas contiguously
- send `deltaBatch`
- otherwise send `snapshot`

Client behavior on delta gap:

- if incoming `previousRevision != lastAppliedRevision`
- enter `stale` state
- request snapshot
- stop applying later deltas until repaired

## Heartbeat And Connection States

Add explicit networking states:

- `idle`
- `browsing`
- `connecting`
- `connectedUnsynced`
- `syncing`
- `ready`
- `stale`
- `failed`

Heartbeat policy:

- host and client may send `ping` every `10s`
- mark peer suspect after one missed interval
- mark disconnected after `30s` without traffic or heartbeat

No reconnect automation is required in the first implementation, but the states should support it.

## Host-Side Implementation Model

This is the most important internal refactor.

Create a single mutation pipeline on the host:

1. receive command
2. validate command
3. apply command to authoritative state via reducer
4. collect domain changes
5. increment revision
6. build delta
7. append delta to log
8. broadcast delta
9. send command receipt

Do not let random view-model methods directly mutate replicated state and then separately decide what to broadcast.

### Recommended New Types

In `Services/Networking/` add:

- `CampaignSessionProtocol.swift`
- `CampaignDeltaModels.swift`
- `CampaignCommandModels.swift`
- `CampaignReplicationState.swift`
- `CampaignMutationReducer.swift`
- `CampaignDeltaLog.swift`

### Recommended Reducer Shape

```swift
struct MutationResult {
    let changes: [CampaignDeltaChange]
}

enum CampaignMutationReducer {
    static func apply(
        _ command: CampaignCommand,
        to state: inout CampaignReplicatedState,
        assignments: inout [PlayerAssignment]
    ) throws -> MutationResult
}
```

Notes:

- reducer owns mutation and change generation
- networking layer owns revisioning, replay, and broadcast
- view model becomes an adapter, not the mutation engine

## Client-Side Apply Model

Client replication logic should be:

1. on `snapshot`, replace local replicated state and set revision
2. on `delta`, require contiguous revision
3. apply typed changes to local state
4. update `lastAppliedRevision`

Recommended helper:

```swift
enum CampaignDeltaApplier {
    static func apply(
        _ delta: CampaignDelta,
        to state: inout CampaignReplicatedState
    ) throws
}
```

## Mapping From Current Code

### Current Files

- `DnDAppSwiftUI/Services/Networking/CampaignNetworkModels.swift`
- `DnDAppSwiftUI/Services/Networking/CampaignNetworkingService.swift`
- `DnDAppSwiftUI/Services/Networking/CampaignSnapshotBuilder.swift`
- `DnDAppSwiftUI/ViewModels/CampaignViewModel+Networking.swift`

### Required Refactor Targets

#### `CampaignNetworkModels.swift`

Replace or extend:

- `CampaignNetworkMessage`
- `PlayerCharacterUpdateEnvelope`
- `PlayerUpdateReceipt`
- `PlayerUpdateRejection`

Add:

- `Welcome`
- `ResumeSession`
- `CampaignCommandEnvelope`
- `CampaignCommandAccepted`
- `CampaignCommandRejected`
- `CampaignDelta`
- `CampaignDeltaBatch`
- `CampaignDeltaChange`

#### `CampaignNetworkingService.swift`

Change responsibilities:

- allow pre-session `hello`
- validate protocol version
- add `welcome`
- track host `currentRevision`
- store recent delta log
- provide send helpers for `delta`, `deltaBatch`, and `snapshot`
- support ready/stale/syncing states

#### `CampaignSnapshotBuilder.swift`

Keep, but narrow its role:

- build full replicated state for `snapshot`
- apply full snapshot to client state

Do not use it as the primary broadcast path for every mutation.

#### `CampaignViewModel+Networking.swift`

Refactor away from:

- `publishNetworkSnapshot(reason:)`
- direct “mutate then snapshot” flow

Replace with:

- `sendCommand(_:)` for client
- `handleIncomingCommand(...)` for host
- `applyHostMutationResult(...)`
- `requestSnapshotIfStale()`

## Transitional Strategy

Do not migrate every domain to fine-grained deltas on day one.

### Phase 1

- fix handshake
- add `welcome`
- add `revision`
- add `snapshot.revision`
- move player update handling into a reducer
- keep snapshot broadcast as fallback

Deliverable:

- protocol v2 handshake works
- no deadlock
- full snapshots still function

### Phase 2

- introduce `command`
- introduce `commandAccepted` / `commandRejected`
- introduce `delta`
- implement fine-grained deltas for:
  - assignments
  - player HP
  - player statuses
  - spell slots
  - action uses
  - inventory equip
  - roll inserts

Deliverable:

- assigned-player interactions no longer trigger full snapshot broadcast

### Phase 3

- add delta log
- add `resumeSession`
- add `deltaBatch`
- add stale detection and snapshot repair

Deliverable:

- reconnect and recovery from missed deltas

### Phase 4

- replace collection-wide fallback deltas with richer tracker and encounter changes
- reduce or remove steady-state snapshot broadcasts for host-side UI actions

Deliverable:

- snapshots become bootstrap/recovery only

## Testing Plan

### Unit Tests

- command validation rules
- reducer mutations
- delta generation per command
- delta applier behavior
- snapshot replacement behavior
- duplicate command handling
- revision gap detection

### Integration Tests

- client hello -> welcome -> snapshot
- resume from retained delta range
- resume falling back to snapshot
- two clients send commands close together
- host emits ordered revisions without client-side conflicts
- duplicate command resend returns same receipt

### Regression Tests For Current Bugs

- pre-session hello send is allowed
- session bootstrap does not require prior `sessionID`
- receiving deltas out of order moves client to `stale`

## Open Decisions

These should be settled before implementation starts:

1. Should `sessionID` remain on the envelope or move into message payloads?
2. Should `baseRevision` be advisory only or enforced for some commands?
3. Should initiative tracker state remain independently authoritative, or be derived from entity state plus tracker metadata?
4. How large should the delta retention window be?
5. Should replay use `deltaBatch` immediately or can replay send repeated `delta` frames first?

## Recommended Answers

1. Keep `sessionID` on envelope for now and allow zero UUID for pre-session messages.
2. Make `baseRevision` advisory in phase 1 and phase 2.
3. Long term, derive combatant live stats from source entities where possible; keep tracker-only fields like `isTurn` and order as tracker state.
4. Start with `500` revisions in memory.
5. Repeated `delta` frames are fine initially; `deltaBatch` can be added in phase 3.

## Summary

The concrete target architecture is:

- host-authoritative canonical state
- client commands only
- serialized host mutation reducer
- monotonic revision numbers
- typed deltas for steady-state sync
- snapshots only for bootstrap and repair
- replay window for reconnect and missed updates

That gives you cleaner concurrency semantics than the current snapshot broadcast model and is the right foundation if multiple clients may send updates near-simultaneously.

