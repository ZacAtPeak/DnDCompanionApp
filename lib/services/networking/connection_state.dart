enum ConnectionStatus {
  idle,
  browsing,
  connecting,
  connectedUnsynced,
  syncing,
  ready,
  stale,
  failed,
}

class ConnectionState {
  final ConnectionStatus status;
  final String? peerName;
  final String? sessionID;
  final String? sessionName;
  final int? currentRevision;
  final String? assignedPlayerID;
  final String? errorMessage;

  const ConnectionState({
    this.status = ConnectionStatus.idle,
    this.peerName,
    this.sessionID,
    this.sessionName,
    this.currentRevision,
    this.assignedPlayerID,
    this.errorMessage,
  });

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? peerName,
    String? sessionID,
    String? sessionName,
    int? currentRevision,
    String? assignedPlayerID,
    String? errorMessage,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      peerName: peerName ?? this.peerName,
      sessionID: sessionID ?? this.sessionID,
      sessionName: sessionName ?? this.sessionName,
      currentRevision: currentRevision ?? this.currentRevision,
      assignedPlayerID: assignedPlayerID ?? this.assignedPlayerID,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  String get displayText {
    switch (status) {
      case ConnectionStatus.idle:
        return 'Disconnected';
      case ConnectionStatus.browsing:
        return 'Browsing...';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connectedUnsynced:
        return 'Connecting to $peerName';
      case ConnectionStatus.syncing:
        return 'Syncing with $peerName';
      case ConnectionStatus.ready:
        return 'Connected: $sessionName';
      case ConnectionStatus.stale:
        return 'Stale: $peerName';
      case ConnectionStatus.failed:
        return 'Failed: $errorMessage';
    }
  }
}
