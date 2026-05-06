import 'package:flutter/material.dart';

import '../providers/campaign_state_provider.dart';
import '../services/networking/campaign_network_client.dart';
import '../services/networking/connection_state.dart' as net;

class NetworkSessionPicker extends StatefulWidget {
  final CampaignNetworkClient client;
  final CampaignStateNotifier notifier;

  const NetworkSessionPicker({
    super.key,
    required this.client,
    required this.notifier,
  });

  @override
  State<NetworkSessionPicker> createState() => _NetworkSessionPickerState();
}

class _NetworkSessionPickerState extends State<NetworkSessionPicker> {
  List<DiscoveredHost> _hosts = [];

  @override
  void initState() {
    super.initState();
    widget.client.discoveredHostsStream.listen((hosts) {
      if (mounted) {
        setState(() => _hosts = hosts);
      }
    });
  }

  @override
  void dispose() {
    if (widget.client.connectionState.status == net.ConnectionStatus.browsing) {
      widget.client.stopBrowsing();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.notifier,
      builder: (context, _) {
        final state = widget.notifier.connectionState;
        return _buildContent(context, state);
      },
    );
  }

  Widget _buildContent(BuildContext context, net.ConnectionState state) {
    switch (state.status) {
      case net.ConnectionStatus.idle:
      case net.ConnectionStatus.failed:
        return _buildIdleView(context, state);
      case net.ConnectionStatus.browsing:
        return _buildBrowsingView(context);
      case net.ConnectionStatus.connecting:
      case net.ConnectionStatus.connectedUnsynced:
      case net.ConnectionStatus.syncing:
        return _buildConnectingView(context, state);
      case net.ConnectionStatus.ready:
      case net.ConnectionStatus.stale:
        return _buildConnectedView(context, state);
    }
  }

  Widget _buildIdleView(BuildContext context, net.ConnectionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wifi_tethering,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            state.status == net.ConnectionStatus.failed
                ? state.errorMessage ?? 'Disconnected'
                : 'No Active Session',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => widget.client.startBrowsing(),
            icon: const Icon(Icons.search),
            label: const Text('Scan for Sessions'),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowsingView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Scanning for sessions...'),
            ],
          ),
        ),
        const Divider(height: 1),
        if (_hosts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No sessions found'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            itemCount: _hosts.length,
            itemBuilder: (context, index) {
              final host = _hosts[index];
              return ListTile(
                leading: const Icon(Icons.computer),
                title: Text(host.name),
                subtitle: Text('${host.host}:${host.port}'),
                trailing: FilledButton(
                  onPressed: () => widget.client.connect(host),
                  child: const Text('Connect'),
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: () => widget.client.stopBrowsing(),
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectingView(BuildContext context, net.ConnectionState state) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            state.displayText,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => widget.client.disconnect(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, net.ConnectionState state) {
    final assignedPlayer = widget.notifier.assignedPlayer;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(
            state.status == net.ConnectionStatus.stale
                ? Icons.warning_amber
                : Icons.check_circle,
            color: state.status == net.ConnectionStatus.stale
                ? Colors.orange
                : Colors.green,
          ),
          title: Text(state.sessionName ?? 'Unknown Session'),
          subtitle: Text(state.displayText),
        ),
        if (state.currentRevision != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Revision: ${state.currentRevision}'),
          ),
        if (assignedPlayer != null) ...[
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield),
            title: Text(assignedPlayer.name),
            subtitle: Text(
                'Level ${assignedPlayer.level} ${assignedPlayer.race} ${assignedPlayer.playerClass}'),
            trailing: Text('${assignedPlayer.currentHP}/${assignedPlayer.maxHP} HP'),
          ),
        ],
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.status == net.ConnectionStatus.stale)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      widget.client.disconnect();
                      widget.client.startBrowsing();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                  ),
                ),
              FilledButton.icon(
                onPressed: () => widget.client.disconnect(),
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
