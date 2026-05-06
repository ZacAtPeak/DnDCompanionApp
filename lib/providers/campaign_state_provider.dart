import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/networking/campaign_network_client.dart';
import '../services/networking/connection_state.dart';
import '../services/networking/models.dart';

class CampaignStateNotifier extends ChangeNotifier {
  final CampaignNetworkClient client;
  ConnectionState _connectionState = const ConnectionState();
  CampaignReplicatedState? _replicatedState;
  String? _assignedPlayerID;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _replicatedStateSubscription;
  bool _disposed = false;
  bool _isShowingCachedState = false;

  CampaignStateNotifier({required this.client}) {
    _stateSubscription = client.connectionStateStream.listen((state) {
      if (!_disposed) {
        _connectionState = state;
        _assignedPlayerID = state.assignedPlayerID;
        notifyListeners();
      }
    });

    _replicatedStateSubscription = client.replicatedStateStream.listen((state) {
      if (!_disposed) {
        _replicatedState = state;
        _isShowingCachedState = false;
        notifyListeners();
      }
    });

    _assignedPlayerID = client.assignedPlayerID;
  }

  ConnectionState get connectionState => _connectionState;
  CampaignReplicatedState? get replicatedState => _replicatedState;
  String? get assignedPlayerID => _assignedPlayerID;
  bool get isShowingCachedState => _isShowingCachedState;

  void loadCachedState({
    required CampaignReplicatedState state,
    String? assignedPlayerID,
  }) {
    _replicatedState = state;
    if (assignedPlayerID != null) _assignedPlayerID = assignedPlayerID;
    _isShowingCachedState = true;
    notifyListeners();
  }

  List<NetworkCombatent> get combatents => _replicatedState?.combatents ?? [];
  List<NetworkPlayerState> get players => _replicatedState?.players ?? [];
  List<NetworkMonsterState> get monsters => _replicatedState?.monsters ?? [];
  List<NetworkNPCState> get npcs => _replicatedState?.npcs ?? [];
  List<RollEntry> get rollHistory => _replicatedState?.rollHistory ?? [];

  void updateState() {
    _connectionState = client.connectionState;
    _replicatedState = client.replicatedState;
    _assignedPlayerID = client.assignedPlayerID;
    notifyListeners();
  }

  NetworkPlayerState? get assignedPlayer {
    if (_assignedPlayerID == null || _replicatedState == null) return null;
    for (final player in _replicatedState!.players) {
      if (player.id == _assignedPlayerID) {
        return player;
      }
    }
    return null;
  }

  NetworkCombatent? get assignedPlayerCombatant {
    if (_assignedPlayerID == null) return null;
    for (final combatent in combatents) {
      if (combatent.entityID == _assignedPlayerID) {
        return combatent;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _disposed = true;
    _stateSubscription?.cancel();
    _replicatedStateSubscription?.cancel();
    super.dispose();
  }
}
