import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connection state enum
enum ConnectionState {
  /// Device is connected to the internet
  connected,
  /// Device is offline (no connectivity)
  offline,
  /// Connection state is unknown or being determined
  unknown,
}

/// Service for monitoring network connectivity
/// 
/// Provides real-time updates about internet connectivity status
/// and handles connection state changes for the app.
class ConnectivityService {
  /// Creates a [ConnectivityService] instance
  ConnectivityService() {
    _initialize();
  }

  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();

  ConnectionState _currentState = ConnectionState.unknown;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Current connection state
  ConnectionState get currentState => _currentState;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// Whether the device is currently connected
  bool get isConnected => _currentState == ConnectionState.connected;

  /// Whether the device is currently offline
  bool get isOffline => _currentState == ConnectionState.offline;

  /// Initialize connectivity monitoring
  Future<void> _initialize() async {
    // Get initial connectivity state
    await _updateConnectionState();

    // Listen for connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      _updateConnectionState();
    });
  }

  /// Update connection state based on connectivity results
  Future<void> _updateConnectionState() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final newState = _determineConnectionState(results);

      if (newState != _currentState) {
        _currentState = newState;
        _connectionStateController.add(_currentState);
      }
    } on Exception {
      // If we can't determine connectivity, assume offline for safety
      if (_currentState != ConnectionState.offline) {
        _currentState = ConnectionState.offline;
        _connectionStateController.add(_currentState);
      }
    }
  }

  /// Determine connection state from connectivity results
  ConnectionState _determineConnectionState(List<ConnectivityResult> results) {
    // If no results or only contains 'none', we're offline
    if (results.isEmpty || 
        results.every((result) => result == ConnectivityResult.none)) {
      return ConnectionState.offline;
    }

    // If we have any non-'none' connectivity, consider it connected
    // Note: This doesn't guarantee internet access, just network connectivity
    return ConnectionState.connected;
  }

  /// Manually refresh connection state
  /// 
  /// Useful for testing or when you need to force a connectivity check
  Future<void> refreshConnectionState() async {
    await _updateConnectionState();
  }

  /// Dispose of resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionStateController.close();
  }
}
