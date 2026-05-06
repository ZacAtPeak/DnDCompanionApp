import 'package:dndappcompanion/services/networking/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CampaignNetworkEnvelope', () {
    test('round-trips through JSON', () {
      final now = DateTime.now().toUtc();
      final envelope = CampaignNetworkEnvelope(
        schemaVersion: 2,
        sessionID: 'test-session-id',
        sentAt: now,
        message: CampaignNetworkMessage(
          type: 'hello',
          payload: {'clientID': 'client-123'},
        ),
      );

      final json = envelope.toJson();
      final restored = CampaignNetworkEnvelope.fromJson(json);

      expect(restored.schemaVersion, equals(2));
      expect(restored.sessionID, equals('test-session-id'));
      expect(restored.sentAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(restored.message.type, equals('hello'));
    });

    test('round-trips through JSON string', () {
      final now = DateTime.now().toUtc();
      final envelope = CampaignNetworkEnvelope(
        sessionID: kZeroUUID,
        sentAt: now,
        message: CampaignNetworkMessage.requestSnapshot(),
      );

      final jsonString = envelope.toJsonString();
      final restored = CampaignNetworkEnvelope.fromJsonString(jsonString);

      expect(restored.sessionID, equals(kZeroUUID));
      expect(restored.message.type, equals('requestSnapshot'));
    });
  });

  group('CampaignCommandEnvelope', () {
    test('round-trips through JSON', () {
      final command = CampaignCommandEnvelope(
        commandID: 'cmd-123',
        clientID: 'client-456',
        baseRevision: 10,
        command: CampaignCommand.setHitPoints(
          playerID: 'player-789',
          currentHP: 25,
          temporaryHP: 5,
        ),
      );

      final json = command.toJson();
      final restored = CampaignCommandEnvelope.fromJson(json);

      expect(restored.commandID, equals('cmd-123'));
      expect(restored.clientID, equals('client-456'));
      expect(restored.baseRevision, equals(10));
      expect(restored.command.type, equals('setHitPoints'));
      expect(restored.command.data['playerID'], equals('player-789'));
      expect(restored.command.data['currentHP'], equals(25));
      expect(restored.command.data['temporaryHP'], equals(5));
    });
  });

  group('CampaignDelta', () {
    test('round-trips through JSON', () {
      final now = DateTime.now().toUtc();
      final delta = CampaignDelta(
        deltaID: 'delta-123',
        revision: 15,
        previousRevision: 14,
        createdAt: now,
        originClientID: 'client-456',
        changes: [
          CampaignDeltaChange(
            type: 'playerHitPointsChanged',
            data: {
              'playerID': 'player-789',
              'currentHP': 30,
              'temporaryHP': 0,
            },
          ),
        ],
      );

      final json = delta.toJson();
      final restored = CampaignDelta.fromJson(json);

      expect(restored.deltaID, equals('delta-123'));
      expect(restored.revision, equals(15));
      expect(restored.previousRevision, equals(14));
      expect(restored.createdAt.millisecondsSinceEpoch, equals(now.millisecondsSinceEpoch));
      expect(restored.originClientID, equals('client-456'));
      expect(restored.changes, hasLength(1));
      expect(restored.changes[0].type, equals('playerHitPointsChanged'));
      expect(restored.changes[0].data['playerID'], equals('player-789'));
      expect(restored.changes[0].data['currentHP'], equals(30));
    });
  });

  group('CampaignCommand', () {
    test('setHitPoints creates correct JSON', () {
      final command = CampaignCommand.setHitPoints(
        playerID: 'p1',
        currentHP: 20,
        temporaryHP: 3,
      );

      expect(command.type, equals('setHitPoints'));
      expect(command.data['playerID'], equals('p1'));
      expect(command.data['currentHP'], equals(20));
      expect(command.data['temporaryHP'], equals(3));
    });

    test('setStatuses creates correct JSON', () {
      final command = CampaignCommand.setStatuses(
        playerID: 'p1',
        statuses: [
          NetworkStatusCondition(
            name: 'Blessed',
            effect: '+d4',
            desc: 'Test',
          ),
        ],
      );

      expect(command.type, equals('setStatuses'));
      expect(command.data['playerID'], equals('p1'));
      expect(command.data['statuses'], hasLength(1));
    });

    test('setSpellSlot creates correct JSON', () {
      final command = CampaignCommand.setSpellSlot(
        playerID: 'p1',
        level: 3,
        available: 2,
      );

      expect(command.type, equals('setSpellSlot'));
      expect(command.data['level'], equals(3));
      expect(command.data['available'], equals(2));
    });

    test('submitRoll creates correct JSON', () {
      final roll = RollEntry(
        type: 'Attack',
        name: 'Longsword',
        roll: 14,
        modifier: 6,
        total: 20,
        timestamp: DateTime.now().toUtc(),
      );
      final command = CampaignCommand.submitRoll(
        playerID: 'p1',
        roll: roll,
      );

      expect(command.type, equals('submitRoll'));
      expect(command.data['roll']['type'], equals('Attack'));
      expect(command.data['roll']['total'], equals(20));
    });
  });

  group('Hello', () {
    test('round-trips through JSON', () {
      final hello = Hello(
        clientID: 'client-123',
        displayName: 'Test Client',
        protocolVersion: 2,
        capabilities: HelloCapabilities(
          supportsDeltaBatch: true,
          supportsResume: true,
        ),
      );

      final json = hello.toJson();
      final restored = Hello.fromJson(json);

      expect(restored.clientID, equals('client-123'));
      expect(restored.displayName, equals('Test Client'));
      expect(restored.protocolVersion, equals(2));
      expect(restored.capabilities.supportsDeltaBatch, isTrue);
      expect(restored.capabilities.supportsResume, isTrue);
    });
  });

  group('CampaignNetworkWelcome', () {
    test('round-trips through JSON', () {
      final welcome = CampaignNetworkWelcome(
        sessionID: 'session-123',
        sessionName: 'Test Session',
        protocolVersion: 2,
        currentRevision: 42,
        heartbeatIntervalMs: 15000,
        deltaRetentionLimit: 1000,
      );

      final json = welcome.toJson();
      final restored = CampaignNetworkWelcome.fromJson(json);

      expect(restored.sessionID, equals('session-123'));
      expect(restored.sessionName, equals('Test Session'));
      expect(restored.currentRevision, equals(42));
      expect(restored.heartbeatIntervalMs, equals(15000));
    });
  });

  group('CampaignNetworkSnapshot', () {
    test('round-trips through JSON', () {
      final now = DateTime.now().toUtc();
      final snapshot = CampaignNetworkSnapshot(
        snapshotID: 'snap-123',
        revision: 50,
        snapshotDate: now,
        state: CampaignReplicatedState(
          dataVersion: 7,
          players: [
            NetworkPlayerState(
              id: 'p1',
              name: 'Test Player',
              race: 'Human',
              playerClass: 'Fighter',
              level: 5,
              background: 'Soldier',
              size: 'medium',
              alignment: 'neutralGood',
              armorClass: 16,
              armorSource: 'Chain Mail',
              currentHP: 35,
              maxHP: 45,
              hitDice: '5d10',
              speed: NetworkMovementSpeed(walk: 30),
              abilityScores: NetworkAbilityScores(
                strength: 16,
                dexterity: 12,
                constitution: 14,
                intelligence: 10,
                wisdom: 10,
                charisma: 8,
              ),
              proficiencyBonus: 3,
            ),
          ],
        ),
      );

      final json = snapshot.toJson();
      final restored = CampaignNetworkSnapshot.fromJson(json);

      expect(restored.snapshotID, equals('snap-123'));
      expect(restored.revision, equals(50));
      expect(restored.state.players, hasLength(1));
      expect(restored.state.players[0].name, equals('Test Player'));
      expect(restored.state.players[0].currentHP, equals(35));
    });
  });
}
