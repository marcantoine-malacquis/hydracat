import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/services/firebase_service.dart';

/// Sync state enumeration
enum SyncStatus {
  /// Sync is idle and ready
  idle,
  
  /// Currently syncing data
  syncing,
  
  /// Sync encountered an error
  error,
  
  /// Sync is disabled (user not authenticated)
  disabled,
}

/// Data model for sync state
@immutable
class SyncState {
  /// Creates a [SyncState] with the specified parameters
  const SyncState({
    required this.status,
    this.lastSyncTime,
    this.errorMessage,
    this.userId,
  });

  /// Current sync status
  final SyncStatus status;
  
  /// Timestamp of last successful sync
  final DateTime? lastSyncTime;
  
  /// Error message if sync failed
  final String? errorMessage;
  
  /// ID of the authenticated user
  final String? userId;

  /// Whether sync is idle and ready
  bool get isIdle => status == SyncStatus.idle;
  
  /// Whether sync is currently in progress
  bool get isSyncing => status == SyncStatus.syncing;
  
  /// Whether sync has encountered an error
  bool get hasError => status == SyncStatus.error;
  
  /// Whether sync is disabled (no authenticated user)
  bool get isDisabled => status == SyncStatus.disabled;

  /// Creates a copy of this sync state with the given fields replaced
  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    String? errorMessage,
    String? userId,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncState &&
        other.status == status &&
        other.lastSyncTime == lastSyncTime &&
        other.errorMessage == errorMessage &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(status, lastSyncTime, errorMessage, userId);
  }
}

/// Notifier class for managing sync state with authentication integration
class SyncNotifier extends StateNotifier<SyncState> {
  /// Creates a [SyncNotifier] with the provided dependencies
  SyncNotifier(this._ref)
      : super(const SyncState(status: SyncStatus.disabled)) {
    _listenToAuthChanges();
  }

  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;
  Timer? _syncTimer;

  /// Listen to authentication state changes
  void _listenToAuthChanges() {
    _ref.listen(
      authProvider,
      (previous, next) => _handleAuthStateChange(next),
    );
  }

  /// Handle authentication state changes
  void _handleAuthStateChange(AuthState authState) {
    switch (authState) {
      case AuthStateAuthenticated(user: final user):
        _enableSyncForUser(user.id);
      case AuthStateUnauthenticated():
        _disableSync();
      case AuthStateLoading():
        // Keep current state during auth loading
        break;
      case AuthStateError():
        _disableSync();
    }
  }

  /// Enable sync for authenticated user
  void _enableSyncForUser(String userId) {
    if (state.userId != userId) {
      // User changed, reset sync state
      state = SyncState(
        status: SyncStatus.idle,
        userId: userId,
      );
    } else if (state.isDisabled) {
      // Re-enable sync for same user
      state = state.copyWith(status: SyncStatus.idle);
    }
  }

  /// Disable sync when user is not authenticated
  void _disableSync() {
    _cancelSyncTimer();
    state = const SyncState(
      status: SyncStatus.disabled,
    );
  }

  /// Start a sync operation
  Future<void> startSync() async {
    // Only sync if user is authenticated
    if (state.isDisabled || state.userId == null) return;

    // Don't start if already syncing
    if (state.isSyncing) return;

    state = state.copyWith(status: SyncStatus.syncing);

    try {
      // Perform actual sync operations here
      // This is where you would:
      // 1. Upload pending local changes to Firestore
      // 2. Download remote changes from Firestore
      // 3. Resolve any conflicts
      
      await _performSync();
      
      state = state.copyWith(
        status: SyncStatus.idle,
        lastSyncTime: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        status: SyncStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Perform the actual sync operations
  Future<void> _performSync() async {
    // This is a placeholder for actual sync logic
    // In a real implementation, this would:
    
    // 1. Get user's Firestore document reference
    final userId = state.userId;
    if (userId == null) throw Exception('No authenticated user');
    
    // 2. Upload any pending local changes
    // await _uploadLocalChanges(userId);
    
    // 3. Download remote changes
    // await _downloadRemoteChanges(userId);
    
    // 4. Update local database
    // await _updateLocalData();
    
    // For now, just simulate some work
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  /// Schedule automatic sync
  void scheduleAutoSync({Duration interval = const Duration(minutes: 5)}) {
    if (state.isDisabled) return;
    
    _cancelSyncTimer();
    _syncTimer = Timer.periodic(interval, (_) => startSync());
  }

  /// Cancel automatic sync timer
  void _cancelSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Force immediate sync
  Future<void> forceSync() async {
    if (state.isDisabled) return;
    
    // Cancel any existing sync
    if (state.isSyncing) return;
    
    await startSync();
  }

  /// Clear error state
  void clearError() {
    if (state.hasError) {
      state = state.copyWith(
        status: SyncStatus.idle,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _cancelSyncTimer();
    super.dispose();
  }
}

/// Provider for Firebase service
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

/// Provider for sync state management
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

/// Convenience provider to check if sync is enabled
final isSyncEnabledProvider = Provider<bool>((ref) {
  final syncState = ref.watch(syncProvider);
  return !syncState.isDisabled;
});

/// Convenience provider to check if currently syncing
final isSyncingProvider = Provider<bool>((ref) {
  final syncState = ref.watch(syncProvider);
  return syncState.isSyncing;
});

/// Convenience provider to get last sync time
final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  final syncState = ref.watch(syncProvider);
  return syncState.lastSyncTime;
});
