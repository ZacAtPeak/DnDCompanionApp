import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'networking/models.dart';

class SessionPersistenceService {
  static const _keyClientID = 'session_client_id';
  static const _keyHost = 'session_host';
  static const _keyPort = 'session_port';
  static const _keyPeerName = 'session_peer_name';
  static const _keySessionName = 'session_name';
  static const _keyAssignedPlayerID = 'session_assigned_player_id';
  static const _keyLastRevision = 'session_last_revision';
  static const _keyReplicatedState = 'session_replicated_state';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hasSavedSession {
    final p = _prefs;
    return p != null && p.containsKey(_keyHost) && p.containsKey(_keyPort);
  }

  String? get clientID => _prefs?.getString(_keyClientID);
  String? get host => _prefs?.getString(_keyHost);
  int? get port => _prefs?.getInt(_keyPort);
  String? get peerName => _prefs?.getString(_keyPeerName);
  String? get sessionName => _prefs?.getString(_keySessionName);
  String? get assignedPlayerID => _prefs?.getString(_keyAssignedPlayerID);
  int get lastRevision => _prefs?.getInt(_keyLastRevision) ?? 0;

  CampaignReplicatedState? get cachedState {
    final json = _prefs?.getString(_keyReplicatedState);
    if (json == null) return null;
    try {
      return CampaignReplicatedState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveClientID(String id) async {
    await _prefs?.setString(_keyClientID, id);
  }

  Future<void> saveSession({
    required String host,
    required int port,
    required String peerName,
    required String sessionName,
    String? assignedPlayerID,
    required int lastRevision,
  }) async {
    final p = _prefs;
    if (p == null) return;
    await Future.wait([
      p.setString(_keyHost, host),
      p.setInt(_keyPort, port),
      p.setString(_keyPeerName, peerName),
      p.setString(_keySessionName, sessionName),
      assignedPlayerID != null
          ? p.setString(_keyAssignedPlayerID, assignedPlayerID)
          : p.remove(_keyAssignedPlayerID),
      p.setInt(_keyLastRevision, lastRevision),
    ]);
  }

  Future<void> saveReplicatedState(CampaignReplicatedState state) async {
    await _prefs?.setString(_keyReplicatedState, jsonEncode(state.toJson()));
  }

  // Clears session connection data and cached state, but preserves clientID
  // so the stable identity is kept for future sessions.
  Future<void> clear() async {
    final p = _prefs;
    if (p == null) return;
    await Future.wait([
      p.remove(_keyHost),
      p.remove(_keyPort),
      p.remove(_keyPeerName),
      p.remove(_keySessionName),
      p.remove(_keyAssignedPlayerID),
      p.remove(_keyLastRevision),
      p.remove(_keyReplicatedState),
    ]);
  }
}
