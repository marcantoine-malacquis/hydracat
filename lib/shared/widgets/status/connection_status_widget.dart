import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/providers/connectivity_provider.dart';
import 'package:hydracat/providers/sync_provider.dart';
import 'package:hydracat/shared/services/connectivity_service.dart'
    as connectivity;

/// A subtle widget that shows connection and sync status
class ConnectionStatusWidget extends ConsumerWidget {
  /// Creates a connection status widget
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);
    final syncState = ref.watch(syncProvider);

    return connectionState.when(
      data: (connection) {
        return _ConnectionStatusIcon(
          connectionState: connection,
          syncState: syncState,
        );
      },
      loading: () => const _ConnectionStatusIcon(
        connectionState: connectivity.ConnectionState.unknown,
      ),
      error: (error, stackTrace) => const _ConnectionStatusIcon(
        connectionState: connectivity.ConnectionState.offline,
      ),
    );
  }
}

class _ConnectionStatusIcon extends StatelessWidget {
  const _ConnectionStatusIcon({
    required this.connectionState,
    this.syncState,
  });

  final connectivity.ConnectionState connectionState;
  final SyncState? syncState;

  @override
  Widget build(BuildContext context) {
    final (icon, color, tooltip) = _getStatusInfo();

    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: () => _showStatusDialog(context),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: const EdgeInsets.all(8),
    );
  }

  (IconData, Color, String) _getStatusInfo() {
    // Determine status based on connection and sync state
    switch (connectionState) {
      case connectivity.ConnectionState.connected:
        if (syncState?.isSyncing ?? false) {
          return (Icons.cloud_sync, Colors.blue, 'Syncing data...');
        }
        if (syncState?.hasError ?? false) {
          return (Icons.cloud_off, Colors.red, 'Sync error - tap for details');
        }
        if (syncState?.isDisabled ?? false) {
          return (Icons.cloud_off, Colors.grey, 'Sync disabled');
        }
        return (Icons.cloud_done, Colors.green, 'Online and synced');

      case connectivity.ConnectionState.offline:
        return (
          Icons.cloud_off,
          Colors.grey.shade600,
          'Offline - data will sync when connected',
        );

      case connectivity.ConnectionState.unknown:
        return (
          Icons.cloud_queue,
          Colors.grey,
          'Checking connection...',
        );
    }
  }

  void _showStatusDialog(BuildContext context) {
    final lastSyncTime = syncState?.lastSyncTime;
    final errorMessage = syncState?.errorMessage;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection & Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(
              icon: Icons.wifi,
              label: 'Connection',
              value: _getConnectionText(),
            ),
            const SizedBox(height: 12),
            _StatusRow(
              icon: Icons.cloud,
              label: 'Sync Status',
              value: _getSyncText(),
            ),
            if (lastSyncTime != null) ...[
              const SizedBox(height: 12),
              _StatusRow(
                icon: Icons.schedule,
                label: 'Last Synced',
                value: _formatLastSync(lastSyncTime),
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getConnectionText() {
    switch (connectionState) {
      case connectivity.ConnectionState.connected:
        return 'Online';
      case connectivity.ConnectionState.offline:
        return 'Offline';
      case connectivity.ConnectionState.unknown:
        return 'Checking...';
    }
  }

  String _getSyncText() {
    if (syncState?.isDisabled ?? false) return 'Disabled (not authenticated)';
    if (syncState?.isOffline ?? false) {
      return 'Offline (will resume when online)';
    }
    if (syncState?.isSyncing ?? false) return 'Syncing...';
    if (syncState?.hasError ?? false) return 'Error';
    if (syncState?.isIdle ?? false) return 'Ready';
    return 'Unknown';
  }

  String _formatLastSync(DateTime lastSync) {
    return AppDateUtils.getRelativeTime(lastSync);
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
