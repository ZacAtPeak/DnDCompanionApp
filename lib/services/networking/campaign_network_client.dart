import 'dart:async';
import 'dart:io';

import 'package:nsd/nsd.dart';
import 'package:uuid/uuid.dart';

import 'connection_state.dart';
import 'framing.dart';
import 'models.dart';

class DiscoveredHost {
  final String name;
  final String host;
  final int port;

  DiscoveredHost({required this.name, required this.host, required this.port});
}

class CampaignNetworkClient {
  final _uuid = const Uuid();
  late String _clientID;

  Discovery? _discovery;
  final List<DiscoveredHost> _discoveredHosts = [];
  final _discoveredHostsController =
      StreamController<List<DiscoveredHost>>.broadcast();

  Socket? _socket;
  final _decoder = FramingDecoder();

  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  ConnectionState _state = const ConnectionState();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnectAttempts = 5;

  String? _sessionID;
  String? _sessionName;
  String? _peerName;
  String? _connectedHost;
  int? _connectedPort;
  int _currentRevision = 0;
  int _lastAppliedRevision = 0;
  int _heartbeatIntervalMs = 10000;
  String? _assignedPlayerID;

  CampaignReplicatedState? _replicatedState;

  final _pendingCommands = <String, Completer<void>>{};

  Stream<List<DiscoveredHost>> get discoveredHostsStream =>
      _discoveredHostsController.stream;
  List<DiscoveredHost> get discoveredHosts => List.unmodifiable(_discoveredHosts);

  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  ConnectionState get connectionState => _state;

  int get lastAppliedRevision => _lastAppliedRevision;
  String? get assignedPlayerID => _assignedPlayerID;
  CampaignReplicatedState? get replicatedState => _replicatedState;
  String? get sessionID => _sessionID;

  CampaignNetworkClient() {
    _clientID = _uuid.v4();
  }

  void _updateState(ConnectionState newState) {
    _state = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  Future<void> startBrowsing() async {
    _discoveredHosts.clear();
    _updateState(const ConnectionState(status: ConnectionStatus.browsing));

    try {
      _discovery = await startDiscovery('_dndapp._tcp', autoResolve: true);
      _discovery!.addServiceListener((service, status) {
        if (status == ServiceStatus.found) {
          final host = service.host ?? service.addresses?.first.address;
          if (host != null && service.port != null) {
            final discovered = DiscoveredHost(
              name: service.name ?? 'Unknown',
              host: host,
              port: service.port!,
            );
            _discoveredHosts.removeWhere((h) => h.name == discovered.name);
            _discoveredHosts.add(discovered);
            _discoveredHostsController.add(List.unmodifiable(_discoveredHosts));
          }
        } else if (status == ServiceStatus.lost) {
          _discoveredHosts.removeWhere((h) => h.name == service.name);
          _discoveredHostsController.add(List.unmodifiable(_discoveredHosts));
        }
      });
    } catch (e) {
      _updateState(ConnectionState(
        status: ConnectionStatus.failed,
        errorMessage: 'Discovery failed: $e',
      ));
    }
  }

  void stopBrowsing() {
    final discovery = _discovery;
    if (discovery != null) {
      stopDiscovery(discovery);
      _discovery = null;
    }
    if (_state.status == ConnectionStatus.browsing) {
      _updateState(const ConnectionState(status: ConnectionStatus.idle));
    }
  }

  // Connection

  Future<void> connect(DiscoveredHost host) async {
    stopBrowsing();
    _connectedHost = host.host;
    _connectedPort = host.port;
    _peerName = host.name;
    _reconnectAttempts = 0;

    _updateState(ConnectionState(
      status: ConnectionStatus.connecting,
      peerName: host.name,
    ));

    try {
      _socket = await Socket.connect(host.host, host.port)
          .timeout(const Duration(seconds: 10));

      _socket!.listen(
        _onSocketData,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      await _sendHello();
    } catch (e) {
      _updateState(ConnectionState(
        status: ConnectionStatus.failed,
        peerName: host.name,
        errorMessage: 'Connection failed: $e',
      ));
      _tryReconnect();
    }
  }

  Future<void> _sendHello() async {
    final hello = Hello(
      clientID: _clientID,
      displayName: 'D&D Companion',
      protocolVersion: 2,
      capabilities: HelloCapabilities(
        supportsDeltaBatch: true,
        supportsResume: true,
      ),
    );
    final envelope = CampaignNetworkEnvelope(
      sessionID: kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.hello(hello),
    );
    await _sendEnvelope(envelope);
    _updateState(_state.copyWith(status: ConnectionStatus.connectedUnsynced));
  }

  Future<void> _sendEnvelope(CampaignNetworkEnvelope envelope) async {
    if (_socket == null) return;
    final json = envelope.toJsonString();
    final framed = framePayload(json);
    _socket!.add(framed);
  }

  // Message handling

  void _onSocketData(List<int> data) {
    final messages = _decoder.feed(data);
    for (final msg in messages) {
      _handleMessage(msg);
    }
  }

  void _handleMessage(String jsonString) {
    try {
      final envelope = CampaignNetworkEnvelope.fromJsonString(jsonString);
      _processEnvelope(envelope);
    } catch (e) {
      // ignore: avoid_print
      print('Failed to parse message: $e');
    }
  }

  void _processEnvelope(CampaignNetworkEnvelope envelope) {
    final msg = envelope.message;
    switch (msg.type) {
      case 'welcome':
        _handleWelcome(msg.payload as Map<String, dynamic>);
      case 'snapshot':
        _handleSnapshot(msg.payload as Map<String, dynamic>);
      case 'delta':
        _handleDelta(msg.payload as Map<String, dynamic>);
      case 'deltaBatch':
        _handleDeltaBatch(msg.payload as Map<String, dynamic>);
      case 'pong':
        _handlePong(msg.payload as String);
      case 'assignmentChanged':
        _handleAssignmentChanged(msg.payload as Map<String, dynamic>);
      case 'commandAccepted':
        _handleCommandAccepted(msg.payload as Map<String, dynamic>);
      case 'commandRejected':
        _handleCommandRejected(msg.payload as Map<String, dynamic>);
      case 'error':
        _handleError(msg.payload as Map<String, dynamic>);
      case 'ping':
        _handlePing(msg.payload as String);
    }
  }

  void _handleWelcome(Map<String, dynamic> payload) {
    final welcome = CampaignNetworkWelcome.fromJson(payload);
    _sessionID = welcome.sessionID;
    _sessionName = welcome.sessionName;
    _currentRevision = welcome.currentRevision;
    _heartbeatIntervalMs = welcome.heartbeatIntervalMs;

    _updateState(_state.copyWith(
      status: ConnectionStatus.syncing,
      sessionID: _sessionID,
      sessionName: _sessionName,
      currentRevision: _currentRevision,
    ));

    _startHeartbeat();

    if (_lastAppliedRevision > 0) {
      _sendResumeSession();
    } else {
      _sendRequestSnapshot();
    }
  }

  void _sendResumeSession() {
    final resume = CampaignResumeSession(
      clientID: _clientID,
      lastAppliedRevision: _lastAppliedRevision,
    );
    final envelope = CampaignNetworkEnvelope(
      sessionID: _sessionID ?? kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.resumeSession(resume),
    );
    _sendEnvelope(envelope);
  }

  void _sendRequestSnapshot() {
    final envelope = CampaignNetworkEnvelope(
      sessionID: _sessionID ?? kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.requestSnapshot(),
    );
    _sendEnvelope(envelope);
  }

  void _handleSnapshot(Map<String, dynamic> payload) {
    final snapshot = CampaignNetworkSnapshot.fromJson(payload);
    _replicatedState = snapshot.state;
    _lastAppliedRevision = snapshot.revision;
    _currentRevision = snapshot.revision;

    for (final assignment in snapshot.state.assignments) {
      if (assignment.clientID == _clientID) {
        _assignedPlayerID = assignment.playerCharacterID;
      }
    }

    _updateState(_state.copyWith(
      status: ConnectionStatus.ready,
      currentRevision: _currentRevision,
      assignedPlayerID: _assignedPlayerID,
    ));
  }

  void _handleDelta(Map<String, dynamic> payload) {
    final delta = CampaignDelta.fromJson(payload);

    if (delta.previousRevision != _lastAppliedRevision) {
      _markStale();
      return;
    }

    _applyDeltaChanges(delta.changes);
    _lastAppliedRevision = delta.revision;
    _currentRevision = delta.revision;

    _updateState(_state.copyWith(
      status: ConnectionStatus.ready,
      currentRevision: _currentRevision,
    ));
  }

  void _handleDeltaBatch(Map<String, dynamic> payload) {
    final batch = CampaignDeltaBatch.fromJson(payload);
    final sortedDeltas = List<CampaignDelta>.from(batch.deltas)
      ..sort((a, b) => a.revision.compareTo(b.revision));

    for (final delta in sortedDeltas) {
      if (delta.previousRevision != _lastAppliedRevision) {
        _markStale();
        return;
      }
      _applyDeltaChanges(delta.changes);
      _lastAppliedRevision = delta.revision;
    }

    _currentRevision = _lastAppliedRevision;
    _updateState(_state.copyWith(
      status: ConnectionStatus.ready,
      currentRevision: _currentRevision,
    ));
  }

  void _applyDeltaChanges(List<CampaignDeltaChange> changes) {
    if (_replicatedState == null) return;

    for (final change in changes) {
      switch (change.type) {
        case 'assignmentChanged':
          final assignment = PlayerAssignment.fromJson(change.data);
          if (assignment.clientID == _clientID) {
            _assignedPlayerID = assignment.playerCharacterID;
          }
        case 'playerHitPointsChanged':
          _applyHitPointsChange(change.data);
        case 'playerStatusesChanged':
          _applyStatusesChange(change.data);
        case 'playerSpellSlotChanged':
          _applySpellSlotChange(change.data);
        case 'playerActionUsesChanged':
          _applyActionUsesChange(change.data);
        case 'playerInventoryItemEquippedChanged':
          _applyInventoryEquippedChange(change.data);
        case 'combatentHitPointsChanged':
          _applyCombatentHitPointsChange(change.data);
        case 'combatentStatusesChanged':
          _applyCombatentStatusesChange(change.data);
        case 'combatentSpellSlotChanged':
          _applyCombatentSpellSlotChange(change.data);
        case 'rollInserted':
          _applyRollInserted(change.data);
        case 'combatentsReplaced':
          _applyCombatentsReplaced(change.data);
        case 'encountersReplaced':
          _applyEncountersReplaced(change.data);
        case 'wikiEntriesReplaced':
          _applyWikiEntriesReplaced(change.data);
        case 'lootItemsReplaced':
          _applyLootItemsReplaced(change.data);
        case 'spellEntriesReplaced':
          _applySpellEntriesReplaced(change.data);
        case 'assetsReplaced':
          _applyAssetsReplaced(change.data);
      }
    }
  }

  void _applyHitPointsChange(Map<String, dynamic> data) {
    final playerID = data['playerID'] as String;
    final currentHP = data['currentHP'] as int;
    final players = _replicatedState!.players.map((p) {
      if (p.id == playerID) {
        return NetworkPlayerState(
          id: p.id,
          name: p.name,
          race: p.race,
          playerClass: p.playerClass,
          level: p.level,
          background: p.background,
          size: p.size,
          alignment: p.alignment,
          armorClass: p.armorClass,
          armorSource: p.armorSource,
          currentHP: currentHP,
          maxHP: p.maxHP,
          hitDice: p.hitDice,
          speed: p.speed,
          abilityScores: p.abilityScores,
          proficiencyBonus: p.proficiencyBonus,
          statuses: p.statuses,
          spellSlots: p.spellSlots,
          actions: p.actions,
          knownSpells: p.knownSpells,
          languages: p.languages,
          initiative: p.initiative,
        );
      }
      return p;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyStatusesChange(Map<String, dynamic> data) {
    final playerID = data['playerID'] as String;
    final statuses = (data['statuses'] as List<dynamic>)
        .map((s) => NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
        .toList();
    final players = _replicatedState!.players.map((p) {
      if (p.id == playerID) {
        return NetworkPlayerState(
          id: p.id,
          name: p.name,
          race: p.race,
          playerClass: p.playerClass,
          level: p.level,
          background: p.background,
          size: p.size,
          alignment: p.alignment,
          armorClass: p.armorClass,
          armorSource: p.armorSource,
          currentHP: p.currentHP,
          maxHP: p.maxHP,
          hitDice: p.hitDice,
          speed: p.speed,
          abilityScores: p.abilityScores,
          proficiencyBonus: p.proficiencyBonus,
          statuses: statuses,
          spellSlots: p.spellSlots,
          actions: p.actions,
          knownSpells: p.knownSpells,
          languages: p.languages,
          initiative: p.initiative,
        );
      }
      return p;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applySpellSlotChange(Map<String, dynamic> data) {
    final playerID = data['playerID'] as String;
    final level = data['level'] as int;
    final available = data['available'] as int;
    final players = _replicatedState!.players.map((p) {
      if (p.id == playerID) {
        final updatedSlots = p.spellSlots.map((s) {
          if (s.level == level) {
            return NetworkSpellSlot(
              level: s.level,
              max: s.max,
              available: available,
            );
          }
          return s;
        }).toList();
        return NetworkPlayerState(
          id: p.id,
          name: p.name,
          race: p.race,
          playerClass: p.playerClass,
          level: p.level,
          background: p.background,
          size: p.size,
          alignment: p.alignment,
          armorClass: p.armorClass,
          armorSource: p.armorSource,
          currentHP: p.currentHP,
          maxHP: p.maxHP,
          hitDice: p.hitDice,
          speed: p.speed,
          abilityScores: p.abilityScores,
          proficiencyBonus: p.proficiencyBonus,
          statuses: p.statuses,
          spellSlots: updatedSlots,
          actions: p.actions,
          knownSpells: p.knownSpells,
          languages: p.languages,
          initiative: p.initiative,
        );
      }
      return p;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyActionUsesChange(Map<String, dynamic> data) {
    final playerID = data['playerID'] as String;
    final actionIndex = data['actionIndex'] as int;
    final remainingUses = data['remainingUses'] as int;
    final players = _replicatedState!.players.map((p) {
      if (p.id == playerID) {
        final updatedActions = p.actions.asMap().entries.map((e) {
          if (e.key == actionIndex) {
            return NetworkAttack(
              id: e.value.id,
              name: e.value.name,
              hitBonus: e.value.hitBonus,
              reach: e.value.reach,
              damageRoll: e.value.damageRoll,
              damageType: e.value.damageType,
              saveDC: e.value.saveDC,
              description: e.value.description,
              maxUses: e.value.maxUses,
              remainingUses: remainingUses,
            );
          }
          return e.value;
        }).toList();
        return NetworkPlayerState(
          id: p.id,
          name: p.name,
          race: p.race,
          playerClass: p.playerClass,
          level: p.level,
          background: p.background,
          size: p.size,
          alignment: p.alignment,
          armorClass: p.armorClass,
          armorSource: p.armorSource,
          currentHP: p.currentHP,
          maxHP: p.maxHP,
          hitDice: p.hitDice,
          speed: p.speed,
          abilityScores: p.abilityScores,
          proficiencyBonus: p.proficiencyBonus,
          statuses: p.statuses,
          spellSlots: p.spellSlots,
          actions: updatedActions,
          knownSpells: p.knownSpells,
          languages: p.languages,
          initiative: p.initiative,
        );
      }
      return p;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyInventoryEquippedChange(Map<String, dynamic> data) {
    final playerID = data['playerID'] as String;
    final inventoryItemID = data['inventoryItemID'] as String;
    final isEquipped = data['isEquipped'] as bool;
    final inventories = Map<String, List<NetworkInventoryItem>>.from(
        _replicatedState!.playerInventories);
    final playerItems = inventories[playerID];
    if (playerItems != null) {
      inventories[playerID] = playerItems.map((item) {
        if (item.id == inventoryItemID) {
          return NetworkInventoryItem(
            id: item.id,
            name: item.name,
            quantity: item.quantity,
            weight: item.weight,
            isEquipped: isEquipped,
            description: item.description,
          );
        }
        return item;
      }).toList();
    }
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: inventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyCombatentHitPointsChange(Map<String, dynamic> data) {
    final combatentID = data['combatentID'] as String;
    final currentHP = data['currentHP'] as int;
    final combatents = _replicatedState!.combatents.map((c) {
      if (c.id == combatentID) {
        return NetworkCombatent(
          id: c.id,
          name: c.name,
          entityType: c.entityType,
          entityID: c.entityID,
          currentHP: currentHP,
          maxHP: c.maxHP,
          temporaryHP: c.temporaryHP,
          statuses: c.statuses,
          spellSlots: c.spellSlots,
          isTurn: c.isTurn,
          initiative: c.initiative,
        );
      }
      return c;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyCombatentStatusesChange(Map<String, dynamic> data) {
    final combatentID = data['combatentID'] as String;
    final statuses = (data['statuses'] as List<dynamic>)
        .map((s) => NetworkStatusCondition.fromJson(s as Map<String, dynamic>))
        .toList();
    final combatents = _replicatedState!.combatents.map((c) {
      if (c.id == combatentID) {
        return NetworkCombatent(
          id: c.id,
          name: c.name,
          entityType: c.entityType,
          entityID: c.entityID,
          currentHP: c.currentHP,
          maxHP: c.maxHP,
          temporaryHP: c.temporaryHP,
          statuses: statuses,
          spellSlots: c.spellSlots,
          isTurn: c.isTurn,
          initiative: c.initiative,
        );
      }
      return c;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyCombatentSpellSlotChange(Map<String, dynamic> data) {
    final combatentID = data['combatentID'] as String;
    final level = data['level'] as int;
    final available = data['available'] as int;
    final combatents = _replicatedState!.combatents.map((c) {
      if (c.id == combatentID) {
        final updatedSlots = c.spellSlots.map((s) {
          if (s.level == level) {
            return NetworkSpellSlot(
              level: s.level,
              max: s.max,
              available: available,
            );
          }
          return s;
        }).toList();
        return NetworkCombatent(
          id: c.id,
          name: c.name,
          entityType: c.entityType,
          entityID: c.entityID,
          currentHP: c.currentHP,
          maxHP: c.maxHP,
          temporaryHP: c.temporaryHP,
          statuses: c.statuses,
          spellSlots: updatedSlots,
          isTurn: c.isTurn,
          initiative: c.initiative,
        );
      }
      return c;
    }).toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyRollInserted(Map<String, dynamic> data) {
    final entry = RollEntry.fromJson(data['entry'] as Map<String, dynamic>);
    final rollHistory = [entry, ..._replicatedState!.rollHistory];
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyCombatentsReplaced(Map<String, dynamic> data) {
    final combatents = (data['combatents'] as List<dynamic>)
        .map((c) => NetworkCombatent.fromJson(c as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyEncountersReplaced(Map<String, dynamic> data) {
    final encounters = (data['encounters'] as List<dynamic>)
        .map((e) => NetworkEncounter.fromJson(e as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyWikiEntriesReplaced(Map<String, dynamic> data) {
    final wikiEntries = (data['wikiEntries'] as List<dynamic>)
        .map((w) => NetworkWikiEntry.fromJson(w as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyLootItemsReplaced(Map<String, dynamic> data) {
    final lootItems = (data['lootItems'] as List<dynamic>)
        .map((l) => NetworkLootItem.fromJson(l as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applySpellEntriesReplaced(Map<String, dynamic> data) {
    final spellEntries = (data['spellEntries'] as List<dynamic>)
        .map((s) => NetworkSpellEntry.fromJson(s as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: spellEntries,
      assets: _replicatedState!.assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _applyAssetsReplaced(Map<String, dynamic> data) {
    final assets = (data['assets'] as List<dynamic>)
        .map((a) => NetworkAsset.fromJson(a as Map<String, dynamic>))
        .toList();
    _replicatedState = CampaignReplicatedState(
      dataVersion: _replicatedState!.dataVersion,
      assignments: _replicatedState!.assignments,
      combatents: _replicatedState!.combatents,
      rollHistory: _replicatedState!.rollHistory,
      encounters: _replicatedState!.encounters,
      playerInventories: _replicatedState!.playerInventories,
      monsterInventories: _replicatedState!.monsterInventories,
      npcInventories: _replicatedState!.npcInventories,
      wikiEntries: _replicatedState!.wikiEntries,
      lootItems: _replicatedState!.lootItems,
      spellEntries: _replicatedState!.spellEntries,
      assets: assets,
      players: _replicatedState!.players,
      monsters: _replicatedState!.monsters,
      npcs: _replicatedState!.npcs,
    );
  }

  void _handleAssignmentChanged(Map<String, dynamic> payload) {
    final assignment = PlayerAssignment.fromJson(payload);
    if (assignment.clientID == _clientID) {
      _assignedPlayerID = assignment.playerCharacterID;
      _updateState(_state.copyWith(assignedPlayerID: _assignedPlayerID));
    }
  }

  // Heartbeat

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: _heartbeatIntervalMs),
      (_) => _sendPing(),
    );
  }

  final _pendingPings = <String, DateTime>{};

  void _sendPing() {
    final pingID = _uuid.v4();
    _pendingPings[pingID] = DateTime.now();
    final envelope = CampaignNetworkEnvelope(
      sessionID: _sessionID ?? kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.ping(pingID),
    );
    _sendEnvelope(envelope);
  }

  void _handlePong(String uuid) {
    _pendingPings.remove(uuid);
  }

  void _handlePing(String uuid) {
    final envelope = CampaignNetworkEnvelope(
      sessionID: _sessionID ?? kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.pong(uuid),
    );
    _sendEnvelope(envelope);
  }

  // Commands

  Future<void> sendCommand(CampaignCommand command) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    if (_state.status != ConnectionStatus.ready) {
      throw StateError('Cannot send command: not in ready state');
    }

    final commandID = _uuid.v4();
    final envelope = CampaignCommandEnvelope(
      commandID: commandID,
      clientID: _clientID,
      baseRevision: _lastAppliedRevision,
      command: command,
    );

    final msgEnvelope = CampaignNetworkEnvelope(
      sessionID: _sessionID ?? kZeroUUID,
      sentAt: DateTime.now().toUtc(),
      message: CampaignNetworkMessage.command(envelope),
    );

    final completer = Completer<void>();
    _pendingCommands[commandID] = completer;

    await _sendEnvelope(msgEnvelope);
    return completer.future;
  }

  Future<void> sendSetHitPoints({
    required int currentHP,
    int? temporaryHP,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.setHitPoints(
      playerID: _assignedPlayerID!,
      currentHP: currentHP,
      temporaryHP: temporaryHP,
    );
    return sendCommand(command);
  }

  Future<void> sendSetStatuses({
    required List<NetworkStatusCondition> statuses,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.setStatuses(
      playerID: _assignedPlayerID!,
      statuses: statuses,
    );
    return sendCommand(command);
  }

  Future<void> sendSetSpellSlot({
    required int level,
    required int available,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.setSpellSlot(
      playerID: _assignedPlayerID!,
      level: level,
      available: available,
    );
    return sendCommand(command);
  }

  Future<void> sendSetActionUses({
    required int actionIndex,
    required int remainingUses,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.setActionUses(
      playerID: _assignedPlayerID!,
      actionIndex: actionIndex,
      remainingUses: remainingUses,
    );
    return sendCommand(command);
  }

  Future<void> sendSetInventoryEquipped({
    required String inventoryItemID,
    required bool isEquipped,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.setInventoryEquipped(
      playerID: _assignedPlayerID!,
      inventoryItemID: inventoryItemID,
      isEquipped: isEquipped,
    );
    return sendCommand(command);
  }

  Future<void> sendSubmitRoll({
    required RollEntry roll,
  }) async {
    if (_assignedPlayerID == null) {
      throw StateError('Cannot send command: no player assignment');
    }
    final command = CampaignCommand.submitRoll(
      playerID: _assignedPlayerID!,
      roll: roll,
    );
    return sendCommand(command);
  }

  void _handleCommandAccepted(Map<String, dynamic> payload) {
    final accepted = CampaignCommandAccepted.fromJson(payload);
    final completer = _pendingCommands.remove(accepted.commandID);
    completer?.complete();
  }

  void _handleCommandRejected(Map<String, dynamic> payload) {
    final rejected = CampaignCommandRejected.fromJson(payload);
    final completer = _pendingCommands.remove(rejected.commandID);
    completer?.completeError(
        Exception('Command rejected: ${rejected.code} - ${rejected.reason}'));
  }

  void _handleError(Map<String, dynamic> payload) {
    final error = CampaignErrorMessage.fromJson(payload);
    _updateState(ConnectionState(
      status: ConnectionStatus.failed,
      errorMessage: '${error.code}: ${error.message}',
    ));
  }

  void _markStale() {
    _updateState(_state.copyWith(status: ConnectionStatus.stale));
    _sendRequestSnapshot();
  }

  // Socket events

  void _onSocketError(Object error) {
    _updateState(ConnectionState(
      status: ConnectionStatus.failed,
      peerName: _peerName,
      errorMessage: 'Socket error: $error',
    ));
    _tryReconnect();
  }

  void _onSocketDone() {
    _updateState(ConnectionState(
      status: ConnectionStatus.failed,
      peerName: _peerName,
      errorMessage: 'Connection closed',
    ));
    _tryReconnect();
  }

  void _tryReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateState(ConnectionState(
        status: ConnectionStatus.failed,
        peerName: _peerName,
        errorMessage: 'Max reconnect attempts reached',
      ));
      return;
    }
    _reconnectAttempts++;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectAttempts * 2), () {
      if (_connectedHost != null && _connectedPort != null) {
        _updateState(const ConnectionState(status: ConnectionStatus.browsing));
        connect(DiscoveredHost(
          name: _peerName ?? 'Unknown',
          host: _connectedHost!,
          port: _connectedPort!,
        ));
      }
    });
  }

  // Disconnect

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _heartbeatTimer?.cancel();
    _socket?.close();
    _socket = null;
    _sessionID = null;
    _sessionName = null;
    _peerName = null;
    _connectedHost = null;
    _connectedPort = null;
    _assignedPlayerID = null;
    _replicatedState = null;
    _lastAppliedRevision = 0;
    _currentRevision = 0;
    _pendingCommands.clear();
    _pendingPings.clear();
    _decoder.reset();
    _updateState(const ConnectionState(status: ConnectionStatus.idle));
  }

  // Dispose

  void dispose() {
    disconnect();
    stopBrowsing();
    _discoveredHostsController.close();
    _connectionStateController.close();
  }
}
