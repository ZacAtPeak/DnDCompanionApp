import 'dart:convert';

const String kZeroUUID = '00000000-0000-0000-0000-000000000000';

int _dateToEpochMs(DateTime dt) => dt.millisecondsSinceEpoch;
DateTime _epochMsToDate(dynamic ms) =>
    DateTime.fromMillisecondsSinceEpoch((ms as num).toInt(), isUtc: true);

// Safely cast JSON numbers to int — servers may send integers as doubles.
int _parseInt(dynamic v) => (v as num).toInt();
int? _parseIntOrNull(dynamic v) => v != null ? (v as num).toInt() : null;

class CampaignNetworkEnvelope {
  final int schemaVersion;
  final String sessionID;
  final DateTime sentAt;
  final CampaignNetworkMessage message;

  CampaignNetworkEnvelope({
    this.schemaVersion = 2,
    required this.sessionID,
    required this.sentAt,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'sessionID': sessionID,
        'sentAt': _dateToEpochMs(sentAt),
        'message': message.toJson(),
      };

  factory CampaignNetworkEnvelope.fromJson(Map<String, dynamic> json) =>
      CampaignNetworkEnvelope(
        schemaVersion: _parseInt(json['schemaVersion']),
        sessionID: json['sessionID'] as String,
        sentAt: _epochMsToDate(_parseInt(json['sentAt'])),
        message: CampaignNetworkMessage.fromJson(
            json['message'] as Map<String, dynamic>),
      );

  String toJsonString() => jsonEncode(toJson());

  factory CampaignNetworkEnvelope.fromJsonString(String s) =>
      CampaignNetworkEnvelope.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

class CampaignNetworkMessage {
  final String type;
  final dynamic payload;

  CampaignNetworkMessage({required this.type, this.payload});

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
      };

  factory CampaignNetworkMessage.fromJson(Map<String, dynamic> json) =>
      CampaignNetworkMessage(
        type: json['type'] as String,
        payload: json['payload'],
      );

  static CampaignNetworkMessage hello(Hello payload) =>
      CampaignNetworkMessage(type: 'hello', payload: payload.toJson());

  static CampaignNetworkMessage welcome(CampaignNetworkWelcome payload) =>
      CampaignNetworkMessage(type: 'welcome', payload: payload.toJson());

  static CampaignNetworkMessage resumeSession(CampaignResumeSession payload) =>
      CampaignNetworkMessage(type: 'resumeSession', payload: payload.toJson());

  static CampaignNetworkMessage requestSnapshot() =>
      CampaignNetworkMessage(type: 'requestSnapshot', payload: null);

  static CampaignNetworkMessage ping(String uuid) =>
      CampaignNetworkMessage(type: 'ping', payload: uuid);

  static CampaignNetworkMessage pong(String uuid) =>
      CampaignNetworkMessage(type: 'pong', payload: uuid);

  static CampaignNetworkMessage error(CampaignErrorMessage payload) =>
      CampaignNetworkMessage(type: 'error', payload: payload.toJson());

  static CampaignNetworkMessage snapshot(CampaignNetworkSnapshot payload) =>
      CampaignNetworkMessage(type: 'snapshot', payload: payload.toJson());

  static CampaignNetworkMessage delta(CampaignDelta payload) =>
      CampaignNetworkMessage(type: 'delta', payload: payload.toJson());

  static CampaignNetworkMessage deltaBatch(CampaignDeltaBatch payload) =>
      CampaignNetworkMessage(type: 'deltaBatch', payload: payload.toJson());

  static CampaignNetworkMessage assignmentChanged(PlayerAssignment payload) =>
      CampaignNetworkMessage(
          type: 'assignmentChanged', payload: payload.toJson());

  static CampaignNetworkMessage command(CampaignCommandEnvelope payload) =>
      CampaignNetworkMessage(type: 'command', payload: payload.toJson());

  static CampaignNetworkMessage commandAccepted(
          CampaignCommandAccepted payload) =>
      CampaignNetworkMessage(
          type: 'commandAccepted', payload: payload.toJson());

  static CampaignNetworkMessage commandRejected(
          CampaignCommandRejected payload) =>
      CampaignNetworkMessage(
          type: 'commandRejected', payload: payload.toJson());
}

class Hello {
  final String clientID;
  final String displayName;
  final int protocolVersion;
  final HelloCapabilities capabilities;

  Hello({
    required this.clientID,
    this.displayName = 'D&D Companion',
    this.protocolVersion = 2,
    required this.capabilities,
  });

  Map<String, dynamic> toJson() => {
        'clientID': clientID,
        'displayName': displayName,
        'protocolVersion': protocolVersion,
        'capabilities': capabilities.toJson(),
      };

  factory Hello.fromJson(Map<String, dynamic> json) => Hello(
        clientID: json['clientID'] as String,
        displayName: json['displayName'] as String? ?? 'D&D Companion',
        protocolVersion: _parseInt(json['protocolVersion']),
        capabilities: HelloCapabilities.fromJson(
            json['capabilities'] as Map<String, dynamic>),
      );
}

class HelloCapabilities {
  final bool supportsDeltaBatch;
  final bool supportsResume;

  HelloCapabilities({
    this.supportsDeltaBatch = true,
    this.supportsResume = true,
  });

  Map<String, dynamic> toJson() => {
        'supportsDeltaBatch': supportsDeltaBatch,
        'supportsResume': supportsResume,
      };

  factory HelloCapabilities.fromJson(Map<String, dynamic> json) =>
      HelloCapabilities(
        supportsDeltaBatch: json['supportsDeltaBatch'] as bool? ?? true,
        supportsResume: json['supportsResume'] as bool? ?? true,
      );
}

class CampaignNetworkWelcome {
  final String sessionID;
  final String sessionName;
  final int protocolVersion;
  final int currentRevision;
  final int heartbeatIntervalMs;
  final int deltaRetentionLimit;

  CampaignNetworkWelcome({
    required this.sessionID,
    required this.sessionName,
    required this.protocolVersion,
    required this.currentRevision,
    this.heartbeatIntervalMs = 10000,
    this.deltaRetentionLimit = 500,
  });

  Map<String, dynamic> toJson() => {
        'sessionID': sessionID,
        'sessionName': sessionName,
        'protocolVersion': protocolVersion,
        'currentRevision': currentRevision,
        'heartbeatIntervalMs': heartbeatIntervalMs,
        'deltaRetentionLimit': deltaRetentionLimit,
      };

  factory CampaignNetworkWelcome.fromJson(Map<String, dynamic> json) =>
      CampaignNetworkWelcome(
        sessionID: json['sessionID'] as String,
        sessionName: json['sessionName'] as String,
        protocolVersion: _parseInt(json['protocolVersion']),
        currentRevision: _parseInt(json['currentRevision']),
        heartbeatIntervalMs: _parseIntOrNull(json['heartbeatIntervalMs']) ?? 10000,
        deltaRetentionLimit: _parseIntOrNull(json['deltaRetentionLimit']) ?? 500,
      );
}

class CampaignResumeSession {
  final String clientID;
  final int lastAppliedRevision;

  CampaignResumeSession({
    required this.clientID,
    required this.lastAppliedRevision,
  });

  Map<String, dynamic> toJson() => {
        'clientID': clientID,
        'lastAppliedRevision': lastAppliedRevision,
      };

  factory CampaignResumeSession.fromJson(Map<String, dynamic> json) =>
      CampaignResumeSession(
        clientID: json['clientID'] as String,
        lastAppliedRevision: _parseInt(json['lastAppliedRevision']),
      );
}

class CampaignErrorMessage {
  final String code;
  final String message;

  CampaignErrorMessage({required this.code, required this.message});

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
      };

  factory CampaignErrorMessage.fromJson(Map<String, dynamic> json) =>
      CampaignErrorMessage(
        code: json['code'] as String,
        message: json['message'] as String,
      );
}

class PlayerAssignment {
  final String clientID;
  final String playerCharacterID;
  final DateTime assignedByHostAt;

  PlayerAssignment({
    required this.clientID,
    required this.playerCharacterID,
    required this.assignedByHostAt,
  });

  Map<String, dynamic> toJson() => {
        'clientID': clientID,
        'playerCharacterID': playerCharacterID,
        'assignedByHostAt': _dateToEpochMs(assignedByHostAt),
      };

  factory PlayerAssignment.fromJson(Map<String, dynamic> json) =>
      PlayerAssignment(
        clientID: json['clientID'] as String,
        playerCharacterID: json['playerCharacterID'] as String,
        assignedByHostAt: _epochMsToDate(_parseInt(json['assignedByHostAt'])),
      );
}

class CampaignNetworkSnapshot {
  final String snapshotID;
  final int revision;
  final DateTime snapshotDate;
  final CampaignReplicatedState state;

  CampaignNetworkSnapshot({
    required this.snapshotID,
    required this.revision,
    required this.snapshotDate,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
        'snapshotID': snapshotID,
        'revision': revision,
        'snapshotDate': _dateToEpochMs(snapshotDate),
        'state': state.toJson(),
      };

  factory CampaignNetworkSnapshot.fromJson(Map<String, dynamic> json) =>
      CampaignNetworkSnapshot(
        snapshotID: json['snapshotID'] as String,
        revision: _parseInt(json['revision']),
        snapshotDate: _epochMsToDate(_parseInt(json['snapshotDate'])),
        state: CampaignReplicatedState.fromJson(
            json['state'] as Map<String, dynamic>),
      );
}

class CampaignReplicatedState {
  final int dataVersion;
  final List<PlayerAssignment> assignments;
  final List<NetworkCombatent> combatents;
  final List<RollEntry> rollHistory;
  final List<NetworkEncounter> encounters;
  final Map<String, List<NetworkInventoryItem>> playerInventories;
  final Map<String, List<NetworkInventoryItem>> monsterInventories;
  final Map<String, List<NetworkInventoryItem>> npcInventories;
  final List<NetworkWikiEntry> wikiEntries;
  final List<NetworkLootItem> lootItems;
  final List<NetworkSpellEntry> spellEntries;
  final List<NetworkAsset> assets;
  final List<NetworkPlayerState> players;
  final List<NetworkMonsterState> monsters;
  final List<NetworkNPCState> npcs;

  CampaignReplicatedState({
    this.dataVersion = 7,
    this.assignments = const [],
    this.combatents = const [],
    this.rollHistory = const [],
    this.encounters = const [],
    this.playerInventories = const {},
    this.monsterInventories = const {},
    this.npcInventories = const {},
    this.wikiEntries = const [],
    this.lootItems = const [],
    this.spellEntries = const [],
    this.assets = const [],
    this.players = const [],
    this.monsters = const [],
    this.npcs = const [],
  });

  Map<String, dynamic> toJson() => {
        'dataVersion': dataVersion,
        'assignments': assignments.map((a) => a.toJson()).toList(),
        'combatents': combatents.map((c) => c.toJson()).toList(),
        'rollHistory': rollHistory.map((r) => r.toJson()).toList(),
        'encounters': encounters.map((e) => e.toJson()).toList(),
        'playerInventories': playerInventories.map(
            (k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
        'monsterInventories': monsterInventories.map(
            (k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
        'npcInventories': npcInventories.map(
            (k, v) => MapEntry(k, v.map((i) => i.toJson()).toList())),
        'wikiEntries': wikiEntries.map((w) => w.toJson()).toList(),
        'lootItems': lootItems.map((l) => l.toJson()).toList(),
        'spellEntries': spellEntries.map((s) => s.toJson()).toList(),
        'assets': assets.map((a) => a.toJson()).toList(),
        'players': players.map((p) => p.toJson()).toList(),
        'monsters': monsters.map((m) => m.toJson()).toList(),
        'npcs': npcs.map((n) => n.toJson()).toList(),
      };

  factory CampaignReplicatedState.fromJson(Map<String, dynamic> json) =>
      CampaignReplicatedState(
        dataVersion: _parseIntOrNull(json['dataVersion']) ?? 7,
        assignments: (json['assignments'] as List<dynamic>?)
                ?.map((a) =>
                    PlayerAssignment.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        combatents: (json['combatents'] as List<dynamic>?)
                ?.map((c) =>
                    NetworkCombatent.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        rollHistory: (json['rollHistory'] as List<dynamic>?)
                ?.map((r) => RollEntry.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        encounters: (json['encounters'] as List<dynamic>?)
                ?.map((e) =>
                    NetworkEncounter.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        playerInventories: _parseInventoryMap(json['playerInventories']),
        monsterInventories: _parseInventoryMap(json['monsterInventories']),
        npcInventories: _parseInventoryMap(json['npcInventories']),
        wikiEntries: (json['wikiEntries'] as List<dynamic>?)
                ?.map((w) =>
                    NetworkWikiEntry.fromJson(w as Map<String, dynamic>))
                .toList() ??
            [],
        lootItems: (json['lootItems'] as List<dynamic>?)
                ?.map((l) =>
                    NetworkLootItem.fromJson(l as Map<String, dynamic>))
                .toList() ??
            [],
        spellEntries: (json['spellEntries'] as List<dynamic>?)
                ?.map((s) =>
                    NetworkSpellEntry.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        assets: (json['assets'] as List<dynamic>?)
                ?.map((a) => NetworkAsset.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        players: (json['players'] as List<dynamic>?)
                ?.map((p) =>
                    NetworkPlayerState.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
        monsters: (json['monsters'] as List<dynamic>?)
                ?.map((m) =>
                    NetworkMonsterState.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        npcs: (json['npcs'] as List<dynamic>?)
                ?.map((n) =>
                    NetworkNPCState.fromJson(n as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static Map<String, List<NetworkInventoryItem>> _parseInventoryMap(
      dynamic json) {
    if (json == null) return {};
    final map = json as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(
          k,
          (v as List<dynamic>)
              .map((i) =>
                  NetworkInventoryItem.fromJson(i as Map<String, dynamic>))
              .toList(),
        ));
  }
}

class CampaignDelta {
  final String deltaID;
  final int revision;
  final int previousRevision;
  final DateTime createdAt;
  final String originClientID;
  final List<CampaignDeltaChange> changes;

  CampaignDelta({
    required this.deltaID,
    required this.revision,
    required this.previousRevision,
    required this.createdAt,
    required this.originClientID,
    required this.changes,
  });

  Map<String, dynamic> toJson() => {
        'deltaID': deltaID,
        'revision': revision,
        'previousRevision': previousRevision,
        'createdAt': _dateToEpochMs(createdAt),
        'originClientID': originClientID,
        'changes': changes.map((c) => c.toJson()).toList(),
      };

  factory CampaignDelta.fromJson(Map<String, dynamic> json) => CampaignDelta(
        deltaID: json['deltaID'] as String,
        revision: _parseInt(json['revision']),
        previousRevision: _parseInt(json['previousRevision']),
        createdAt: _epochMsToDate(_parseInt(json['createdAt'])),
        originClientID: json['originClientID'] as String,
        changes: (json['changes'] as List<dynamic>)
            .map((c) =>
                CampaignDeltaChange.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class CampaignDeltaBatch {
  final int fromRevision;
  final int toRevision;
  final List<CampaignDelta> deltas;

  CampaignDeltaBatch({
    required this.fromRevision,
    required this.toRevision,
    required this.deltas,
  });

  Map<String, dynamic> toJson() => {
        'fromRevision': fromRevision,
        'toRevision': toRevision,
        'deltas': deltas.map((d) => d.toJson()).toList(),
      };

  factory CampaignDeltaBatch.fromJson(Map<String, dynamic> json) =>
      CampaignDeltaBatch(
        fromRevision: _parseInt(json['fromRevision']),
        toRevision: _parseInt(json['toRevision']),
        deltas: (json['deltas'] as List<dynamic>)
            .map((d) => CampaignDelta.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

class CampaignDeltaChange {
  final String type;
  final Map<String, dynamic> data;

  CampaignDeltaChange({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, ...data};

  factory CampaignDeltaChange.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json)..remove('type');
    return CampaignDeltaChange(type: type, data: data);
  }
}

class CampaignCommandEnvelope {
  final String commandID;
  final String clientID;
  final int baseRevision;
  final CampaignCommand command;

  CampaignCommandEnvelope({
    required this.commandID,
    required this.clientID,
    required this.baseRevision,
    required this.command,
  });

  Map<String, dynamic> toJson() => {
        'commandID': commandID,
        'clientID': clientID,
        'baseRevision': baseRevision,
        'command': command.toJson(),
      };

  factory CampaignCommandEnvelope.fromJson(Map<String, dynamic> json) =>
      CampaignCommandEnvelope(
        commandID: json['commandID'] as String,
        clientID: json['clientID'] as String,
        baseRevision: _parseInt(json['baseRevision']),
        command: CampaignCommand.fromJson(json['command'] as Map<String, dynamic>),
      );
}

class CampaignCommandAccepted {
  final String commandID;
  final int appliedRevision;
  final DateTime appliedAt;

  CampaignCommandAccepted({
    required this.commandID,
    required this.appliedRevision,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() => {
        'commandID': commandID,
        'appliedRevision': appliedRevision,
        'appliedAt': _dateToEpochMs(appliedAt),
      };

  factory CampaignCommandAccepted.fromJson(Map<String, dynamic> json) =>
      CampaignCommandAccepted(
        commandID: json['commandID'] as String,
        appliedRevision: _parseInt(json['appliedRevision']),
        appliedAt: _epochMsToDate(_parseInt(json['appliedAt'])),
      );
}

class CampaignCommandRejected {
  final String commandID;
  final DateTime rejectedAt;
  final String code;
  final String reason;

  CampaignCommandRejected({
    required this.commandID,
    required this.rejectedAt,
    required this.code,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'commandID': commandID,
        'rejectedAt': _dateToEpochMs(rejectedAt),
        'code': code,
        'reason': reason,
      };

  factory CampaignCommandRejected.fromJson(Map<String, dynamic> json) =>
      CampaignCommandRejected(
        commandID: json['commandID'] as String,
        rejectedAt: _epochMsToDate(_parseInt(json['rejectedAt'])),
        code: json['code'] as String,
        reason: json['reason'] as String,
      );
}

class CampaignCommand {
  final String type;
  final Map<String, dynamic> data;

  CampaignCommand({required this.type, required this.data});

  Map<String, dynamic> toJson() => {'type': type, ...data};

  factory CampaignCommand.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final data = Map<String, dynamic>.from(json)..remove('type');
    return CampaignCommand(type: type, data: data);
  }

  static CampaignCommand setHitPoints({
    required String playerID,
    required int currentHP,
    int? temporaryHP,
  }) =>
      CampaignCommand(
        type: 'setHitPoints',
        data: {
        'playerID': playerID,
        'currentHP': currentHP,
        'temporaryHP': temporaryHP,
        },
      );

  static CampaignCommand setStatuses({
    required String playerID,
    required List<NetworkStatusCondition> statuses,
  }) =>
      CampaignCommand(
        type: 'setStatuses',
        data: {
          'playerID': playerID,
          'statuses': statuses.map((s) => s.toJson()).toList(),
        },
      );

  static CampaignCommand setSpellSlot({
    required String playerID,
    required int level,
    required int available,
  }) =>
      CampaignCommand(
        type: 'setSpellSlot',
        data: {
          'playerID': playerID,
          'level': level,
          'available': available,
        },
      );

  static CampaignCommand setActionUses({
    required String playerID,
    required int actionIndex,
    required int remainingUses,
  }) =>
      CampaignCommand(
        type: 'setActionUses',
        data: {
          'playerID': playerID,
          'actionIndex': actionIndex,
          'remainingUses': remainingUses,
        },
      );

  static CampaignCommand setInventoryEquipped({
    required String playerID,
    required String inventoryItemID,
    required bool isEquipped,
  }) =>
      CampaignCommand(
        type: 'setInventoryEquipped',
        data: {
          'playerID': playerID,
          'inventoryItemID': inventoryItemID,
          'isEquipped': isEquipped,
        },
      );

  static CampaignCommand submitRoll({
    required String playerID,
    required RollEntry roll,
  }) =>
      CampaignCommand(
        type: 'submitRoll',
        data: {
          'playerID': playerID,
          'roll': roll.toJson(),
        },
      );
}

class RollEntry {
  final String type;
  final String name;
  final int roll;
  final int modifier;
  final int total;
  final DateTime timestamp;

  RollEntry({
    required this.type,
    required this.name,
    required this.roll,
    required this.modifier,
    required this.total,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'roll': roll,
        'modifier': modifier,
        'total': total,
        'timestamp': _dateToEpochMs(timestamp),
      };

  factory RollEntry.fromJson(Map<String, dynamic> json) => RollEntry(
        type: json['type'] as String,
        name: json['name'] as String,
        roll: _parseInt(json['roll']),
        modifier: _parseInt(json['modifier']),
        total: _parseInt(json['total']),
        timestamp: _epochMsToDate(_parseInt(json['timestamp'])),
      );
}

class NetworkStatusCondition {
  final String name;
  final String effect;
  final String desc;

  NetworkStatusCondition({
    required this.name,
    required this.effect,
    required this.desc,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'effect': effect,
        'desc': desc,
      };

  factory NetworkStatusCondition.fromJson(Map<String, dynamic> json) =>
      NetworkStatusCondition(
        name: json['name'] as String,
        effect: json['effect'] as String,
        desc: json['desc'] as String,
      );
}

class NetworkSpellSlot {
  final int level;
  final int max;
  final int available;

  NetworkSpellSlot({
    required this.level,
    required this.max,
    required this.available,
  });

  Map<String, dynamic> toJson() => {
        'level': level,
        'max': max,
        'available': available,
      };

  factory NetworkSpellSlot.fromJson(Map<String, dynamic> json) =>
      NetworkSpellSlot(
        level: _parseInt(json['level']),
        max: _parseInt(json['max']),
        available: _parseInt(json['available']),
      );
}

class NetworkAttack {
  final String id;
  final String name;
  final int hitBonus;
  final String reach;
  final String damageRoll;
  final String damageType;
  final int? saveDC;
  final String? description;
  final int? maxUses;
  final int? remainingUses;

  NetworkAttack({
    required this.id,
    required this.name,
    required this.hitBonus,
    required this.reach,
    required this.damageRoll,
    required this.damageType,
    this.saveDC,
    this.description,
    this.maxUses,
    this.remainingUses,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hitBonus': hitBonus,
        'reach': reach,
        'damageRoll': damageRoll,
        'damageType': damageType,
        'saveDC': saveDC,
        'description': description,
        'maxUses': maxUses,
        'remainingUses': remainingUses,
      };

  factory NetworkAttack.fromJson(Map<String, dynamic> json) => NetworkAttack(
        id: json['id'] as String,
        name: json['name'] as String,
        hitBonus: _parseInt(json['hitBonus']),
        reach: json['reach'] as String? ?? '',
        damageRoll: json['damageRoll'] as String? ?? '',
        damageType: json['damageType'] as String? ?? '',
        saveDC: _parseIntOrNull(json['saveDC']),
        description: json['description'] as String?,
        maxUses: _parseIntOrNull(json['maxUses']),
        remainingUses: _parseIntOrNull(json['remainingUses']),
      );
}

class NetworkCombatent {
  final String id;
  final String name;
  final String entityType;
  final String entityID;
  final int currentHP;
  final int maxHP;
  final int temporaryHP;
  final List<NetworkStatusCondition> statuses;
  final List<NetworkSpellSlot> spellSlots;
  final bool isTurn;
  final double initiative;

  NetworkCombatent({
    required this.id,
    required this.name,
    required this.entityType,
    required this.entityID,
    this.currentHP = 0,
    this.maxHP = 0,
    this.temporaryHP = 0,
    this.statuses = const [],
    this.spellSlots = const [],
    this.isTurn = false,
    this.initiative = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entityType': entityType,
        'entityID': entityID,
        'currentHP': currentHP,
        'maxHP': maxHP,
        'temporaryHP': temporaryHP,
        'statuses': statuses.map((s) => s.toJson()).toList(),
        'spellSlots': spellSlots.map((s) => s.toJson()).toList(),
        'isTurn': isTurn,
        'initiative': initiative,
      };

  factory NetworkCombatent.fromJson(Map<String, dynamic> json) =>
      NetworkCombatent(
        id: json['id'] as String,
        name: json['name'] as String,
        entityType: json['entityType'] as String? ??
            json['sourceEntityType'] as String? ?? '',
        entityID: json['entityID'] as String? ??
            json['sourceEntityID'] as String? ?? '',
        currentHP: _parseIntOrNull(json['currentHP']) ?? 0,
        maxHP: _parseIntOrNull(json['maxHP']) ?? 0,
        temporaryHP: _parseIntOrNull(json['temporaryHP']) ?? 0,
        statuses: ((json['statuses'] ?? json['status']) as List<dynamic>?)
                ?.map((s) =>
                    NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        spellSlots: (json['spellSlots'] as List<dynamic>?)
                ?.map((s) =>
                    NetworkSpellSlot.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        isTurn: json['isTurn'] as bool? ?? false,
        initiative: (json['initiative'] as num?)?.toDouble() ?? 0,
      );
}

class NetworkMovementSpeed {
  final int walk;
  final int? swim;
  final int? fly;
  final int? climb;
  final int? burrow;
  final bool hover;

  NetworkMovementSpeed({
    required this.walk,
    this.swim,
    this.fly,
    this.climb,
    this.burrow,
    this.hover = false,
  });

  Map<String, dynamic> toJson() => {
        'walk': walk,
        'swim': swim,
        'fly': fly,
        'climb': climb,
        'burrow': burrow,
        'hover': hover,
      };

  factory NetworkMovementSpeed.fromJson(Map<String, dynamic> json) =>
      NetworkMovementSpeed(
        walk: _parseInt(json['walk']),
        swim: _parseIntOrNull(json['swim']),
        fly: _parseIntOrNull(json['fly']),
        climb: _parseIntOrNull(json['climb']),
        burrow: _parseIntOrNull(json['burrow']),
        hover: json['hover'] as bool? ?? false,
      );
}

class NetworkInventoryItem {
  final String id;
  final String name;
  final int quantity;
  final double weight;
  final bool isEquipped;
  final String? description;

  NetworkInventoryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.weight = 0,
    this.isEquipped = false,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'weight': weight,
        'isEquipped': isEquipped,
        'description': description,
      };

  factory NetworkInventoryItem.fromJson(Map<String, dynamic> json) =>
      NetworkInventoryItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? json['lootItemID'] as String? ?? '',
        quantity: _parseIntOrNull(json['quantity']) ?? 1,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        isEquipped: json['isEquipped'] as bool? ?? false,
        description: json['description'] as String?,
      );
}

class NetworkAbilityScores {
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  NetworkAbilityScores({
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
  });

  Map<String, dynamic> toJson() => {
        'strength': strength,
        'dexterity': dexterity,
        'constitution': constitution,
        'intelligence': intelligence,
        'wisdom': wisdom,
        'charisma': charisma,
      };

  factory NetworkAbilityScores.fromJson(Map<String, dynamic> json) =>
      NetworkAbilityScores(
        strength: _parseInt(json['strength']),
        dexterity: _parseInt(json['dexterity']),
        constitution: _parseInt(json['constitution']),
        intelligence: _parseInt(json['intelligence']),
        wisdom: _parseInt(json['wisdom']),
        charisma: _parseInt(json['charisma']),
      );
}

class NetworkPlayerState {
  final String id;
  final String name;
  final String race;
  final String playerClass;
  final int level;
  final String background;
  final String size;
  final String alignment;
  final int armorClass;
  final String armorSource;
  final int currentHP;
  final int maxHP;
  final String hitDice;
  final NetworkMovementSpeed speed;
  final NetworkAbilityScores abilityScores;
  final int proficiencyBonus;
  final List<NetworkStatusCondition> statuses;
  final List<NetworkSpellSlot> spellSlots;
  final List<NetworkAttack> actions;
  final List<String> knownSpells;
  final List<String> languages;
  final double initiative;

  NetworkPlayerState({
    required this.id,
    required this.name,
    required this.race,
    required this.playerClass,
    required this.level,
    required this.background,
    required this.size,
    required this.alignment,
    required this.armorClass,
    required this.armorSource,
    required this.currentHP,
    required this.maxHP,
    required this.hitDice,
    required this.speed,
    required this.abilityScores,
    required this.proficiencyBonus,
    this.statuses = const [],
    this.spellSlots = const [],
    this.actions = const [],
    this.knownSpells = const [],
    this.languages = const [],
    this.initiative = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'race': race,
        'playerClass': playerClass,
        'level': level,
        'background': background,
        'size': size,
        'alignment': alignment,
        'armorClass': armorClass,
        'armorSource': armorSource,
        'currentHP': currentHP,
        'maxHP': maxHP,
        'hitDice': hitDice,
        'speed': speed.toJson(),
        'abilityScores': abilityScores.toJson(),
        'proficiencyBonus': proficiencyBonus,
        'statuses': statuses.map((s) => s.toJson()).toList(),
        'spellSlots': spellSlots.map((s) => s.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'knownSpells': knownSpells,
        'languages': languages,
        'initiative': initiative,
      };

  factory NetworkPlayerState.fromJson(Map<String, dynamic> json) =>
      NetworkPlayerState(
        id: json['id'] as String,
        name: json['name'] as String,
        race: json['race'] as String? ?? '',
        playerClass: json['playerClass'] as String? ?? '',
        level: _parseIntOrNull(json['level']) ?? 0,
        background: json['background'] as String? ?? '',
        size: json['size'] as String? ?? '',
        alignment: json['alignment'] as String? ?? '',
        armorClass: _parseIntOrNull(json['armorClass']) ?? 0,
        armorSource: json['armorSource'] as String? ?? '',
        currentHP: _parseIntOrNull(json['currentHP']) ?? 0,
        maxHP: _parseIntOrNull(json['maxHP']) ?? 0,
        hitDice: json['hitDice'] as String? ?? '',
        speed: json['speed'] != null
            ? NetworkMovementSpeed.fromJson(
                json['speed'] as Map<String, dynamic>)
            : NetworkMovementSpeed(walk: 30),
        abilityScores: NetworkAbilityScores.fromJson(
            json['abilityScores'] as Map<String, dynamic>),
        proficiencyBonus: _parseIntOrNull(json['proficiencyBonus']) ?? 0,
        statuses: ((json['statuses'] ?? json['status']) as List<dynamic>?)
                ?.map((s) =>
                    NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        spellSlots: (json['spellSlots'] as List<dynamic>?)
                ?.map((s) =>
                    NetworkSpellSlot.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        actions: (json['actions'] as List<dynamic>?)
                ?.map((a) => NetworkAttack.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        knownSpells: (json['knownSpells'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        languages: (json['languages'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        initiative: (json['initiative'] as num?)?.toDouble() ?? 0,
      );
}

class NetworkMonsterState {
  final String id;
  final String name;
  final String size;
  final String type;
  final String alignment;
  final int armorClass;
  final String armorSource;
  final int currentHP;
  final int maxHP;
  final String hitDice;
  final NetworkMovementSpeed speed;
  final NetworkAbilityScores abilityScores;
  final int proficiencyBonus;
  final List<NetworkStatusCondition> statuses;
  final List<NetworkAttack> actions;
  final double challengeRating;
  final int xp;
  final double initiative;

  NetworkMonsterState({
    required this.id,
    required this.name,
    required this.size,
    required this.type,
    required this.alignment,
    required this.armorClass,
    required this.armorSource,
    required this.currentHP,
    required this.maxHP,
    required this.hitDice,
    required this.speed,
    required this.abilityScores,
    required this.proficiencyBonus,
    this.statuses = const [],
    this.actions = const [],
    required this.challengeRating,
    required this.xp,
    this.initiative = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'size': size,
        'type': type,
        'alignment': alignment,
        'armorClass': armorClass,
        'armorSource': armorSource,
        'currentHP': currentHP,
        'maxHP': maxHP,
        'hitDice': hitDice,
        'speed': speed.toJson(),
        'abilityScores': abilityScores.toJson(),
        'proficiencyBonus': proficiencyBonus,
        'statuses': statuses.map((s) => s.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'challengeRating': challengeRating,
        'xp': xp,
        'initiative': initiative,
      };

  factory NetworkMonsterState.fromJson(Map<String, dynamic> json) =>
      NetworkMonsterState(
        id: json['id'] as String,
        name: json['name'] as String,
        size: json['size'] as String? ?? '',
        type: json['type'] as String? ?? '',
        alignment: json['alignment'] as String? ?? '',
        armorClass: _parseIntOrNull(json['armorClass']) ?? 0,
        armorSource: json['armorSource'] as String? ?? '',
        currentHP: _parseIntOrNull(json['currentHP']) ?? 0,
        maxHP: _parseIntOrNull(json['maxHP']) ?? 0,
        hitDice: json['hitDice'] as String? ?? '',
        speed: json['speed'] != null
            ? NetworkMovementSpeed.fromJson(
                json['speed'] as Map<String, dynamic>)
            : NetworkMovementSpeed(walk: 30),
        abilityScores: NetworkAbilityScores.fromJson(
            json['abilityScores'] as Map<String, dynamic>),
        proficiencyBonus: _parseIntOrNull(json['proficiencyBonus']) ?? 0,
        statuses: ((json['statuses'] ?? json['status']) as List<dynamic>?)
                ?.map((s) =>
                    NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        actions: (json['actions'] as List<dynamic>?)
                ?.map((a) => NetworkAttack.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        challengeRating: (json['challengeRating'] as num?)?.toDouble() ?? 0,
        xp: _parseIntOrNull(json['xp']) ?? 0,
        initiative: (json['initiative'] as num?)?.toDouble() ?? 0,
      );
}

class NetworkNPCState {
  final String id;
  final String name;
  final String role;
  final String size;
  final String alignment;
  final String biography;
  final int armorClass;
  final String armorSource;
  final int currentHP;
  final int maxHP;
  final String hitDice;
  final NetworkMovementSpeed speed;
  final NetworkAbilityScores abilityScores;
  final int proficiencyBonus;
  final List<NetworkStatusCondition> statuses;
  final List<NetworkAttack> actions;
  final List<NetworkSpellSlot> spellSlots;
  final List<String> knownSpells;
  final double initiative;

  NetworkNPCState({
    required this.id,
    required this.name,
    required this.role,
    required this.size,
    required this.alignment,
    required this.biography,
    required this.armorClass,
    required this.armorSource,
    required this.currentHP,
    required this.maxHP,
    required this.hitDice,
    required this.speed,
    required this.abilityScores,
    required this.proficiencyBonus,
    this.statuses = const [],
    this.actions = const [],
    this.spellSlots = const [],
    this.knownSpells = const [],
    this.initiative = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'size': size,
        'alignment': alignment,
        'biography': biography,
        'armorClass': armorClass,
        'armorSource': armorSource,
        'currentHP': currentHP,
        'maxHP': maxHP,
        'hitDice': hitDice,
        'speed': speed.toJson(),
        'abilityScores': abilityScores.toJson(),
        'proficiencyBonus': proficiencyBonus,
        'statuses': statuses.map((s) => s.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'spellSlots': spellSlots.map((s) => s.toJson()).toList(),
        'knownSpells': knownSpells,
        'initiative': initiative,
      };

  factory NetworkNPCState.fromJson(Map<String, dynamic> json) =>
      NetworkNPCState(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String? ?? '',
        size: json['size'] as String? ?? '',
        alignment: json['alignment'] as String? ?? '',
        biography: json['biography'] as String? ?? '',
        armorClass: _parseIntOrNull(json['armorClass']) ?? 0,
        armorSource: json['armorSource'] as String? ?? '',
        currentHP: _parseIntOrNull(json['currentHP']) ?? 0,
        maxHP: _parseIntOrNull(json['maxHP']) ?? 0,
        hitDice: json['hitDice'] as String? ?? '',
        speed: json['speed'] != null
            ? NetworkMovementSpeed.fromJson(
                json['speed'] as Map<String, dynamic>)
            : NetworkMovementSpeed(walk: 30),
        abilityScores: NetworkAbilityScores.fromJson(
            json['abilityScores'] as Map<String, dynamic>),
        proficiencyBonus: _parseIntOrNull(json['proficiencyBonus']) ?? 0,
        statuses: ((json['statuses'] ?? json['status']) as List<dynamic>?)
                ?.map((s) =>
                    NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        actions: (json['actions'] as List<dynamic>?)
                ?.map((a) => NetworkAttack.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        spellSlots: (json['spellSlots'] as List<dynamic>?)
                ?.map((s) =>
                    NetworkSpellSlot.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        knownSpells: (json['knownSpells'] as List<dynamic>?)
                ?.map((s) => s as String)
                .toList() ??
            [],
        initiative: (json['initiative'] as num?)?.toDouble() ?? 0,
      );
}

class NetworkWikiEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  NetworkWikiEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': _dateToEpochMs(createdAt),
      };

  factory NetworkWikiEntry.fromJson(Map<String, dynamic> json) =>
      NetworkWikiEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String? ??
            json['description'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? _epochMsToDate(json['createdAt'])
            : DateTime.now(),
      );
}

class NetworkLootItem {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final bool isDivided;

  NetworkLootItem({
    required this.id,
    required this.name,
    required this.description,
    this.quantity = 1,
    this.isDivided = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'quantity': quantity,
        'isDivided': isDivided,
      };

  factory NetworkLootItem.fromJson(Map<String, dynamic> json) =>
      NetworkLootItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        quantity: _parseIntOrNull(json['quantity']) ?? 1,
        isDivided: json['isDivided'] as bool? ?? false,
      );
}

class NetworkItemModifier {
  final String id;
  final String name;
  final int bonus;
  final String? description;

  NetworkItemModifier({
    required this.id,
    required this.name,
    required this.bonus,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bonus': bonus,
        'description': description,
      };

  factory NetworkItemModifier.fromJson(Map<String, dynamic> json) =>
      NetworkItemModifier(
        id: json['id'] as String,
        name: json['name'] as String,
        bonus: _parseInt(json['bonus']),
        description: json['description'] as String?,
      );
}

class NetworkSpellEntry {
  final String id;
  final String name;
  final int level;
  final String school;
  final String description;
  final String castingTime;
  final String range;
  final String components;
  final String duration;

  NetworkSpellEntry({
    required this.id,
    required this.name,
    required this.level,
    required this.school,
    required this.description,
    required this.castingTime,
    required this.range,
    required this.components,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'school': school,
        'description': description,
        'castingTime': castingTime,
        'range': range,
        'components': components,
        'duration': duration,
      };

  factory NetworkSpellEntry.fromJson(Map<String, dynamic> json) =>
      NetworkSpellEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        level: _parseInt(json['level']),
        school: json['school'] as String? ?? '',
        description: json['description'] as String? ?? '',
        castingTime: json['castingTime'] as String? ?? '',
        range: json['range'] as String? ?? '',
        components: json['components'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
      );
}

class NetworkAsset {
  final String id;
  final String name;
  final String type;
  final String? description;

  NetworkAsset({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'description': description,
      };

  factory NetworkAsset.fromJson(Map<String, dynamic> json) => NetworkAsset(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        description: json['description'] as String?,
      );
}

class NetworkEncounter {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  NetworkEncounter({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': _dateToEpochMs(createdAt),
      };

  factory NetworkEncounter.fromJson(Map<String, dynamic> json) =>
      NetworkEncounter(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? _epochMsToDate(json['createdAt'])
            : DateTime.now(),
      );
}
