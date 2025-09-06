import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/shared/services/connectivity_service.dart';

/// Provider for the ConnectivityService instance
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();

  // Dispose service when provider is disposed
  ref.onDispose(service.dispose);

  return service;
});

/// Provider for the current connection state
final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionStateStream;
});

/// Convenience provider to check if device is connected
final isConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  return connectionState.when(
    data: (state) => state == ConnectionState.connected,
    loading: () => false, // Assume offline while loading for safety
    error: (_, _) => false, // Assume offline on error for safety
  );
});

/// Convenience provider to check if device is offline
final isOfflineProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(connectionStateProvider);
  return connectionState.when(
    data: (state) => state == ConnectionState.offline,
    loading: () => true, // Assume offline while loading for safety
    error: (_, _) => true, // Assume offline on error for safety
  );
});
