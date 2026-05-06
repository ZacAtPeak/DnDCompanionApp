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
  bool _disposed = false;

  CampaignStateNotifier({required this.client}) {
    _stateSubscription = client.connectionStateStream.listen((state) {
      if (!_disposed) {
        _connectionState = state;
        notifyListeners();
      }
    });
  }

  ConnectionState get connectionState => _connectionState;
  CampaignReplicatedState? get replicatedState => _replicatedState;
  String? get assignedPlayerID => _assignedPlayerID;

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

  @override
  void dispose() {
    _disposed = true;
    _stateSubscription?.cancel();
    super.dispose();
  }
}
