import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// Mixin that provides unified loading state management for auth screens.
///
/// This mixin standardizes loading state computation while supporting
/// both auth provider loading and optional local loading states.
mixin AuthLoadingStateMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Local loading state for screen-specific operations
  bool _localLoading = false;

  /// Returns true if the auth provider is in loading state
  bool get isAuthLoading {
    return ref.watch(authIsLoadingProvider);
  }

  /// Returns true if local loading is active
  bool get isLocalLoading => _localLoading;

  /// Returns true if either auth or local loading is active
  bool get isLoading => isAuthLoading || _localLoading;

  /// Sets the local loading state
  void setLocalLoading({required bool loading}) {
    if (mounted) {
      setState(() {
        _localLoading = loading;
      });
    }
  }

  /// Executes an async operation with local loading state management
  Future<R?> withLocalLoading<R>(Future<R> operation) async {
    setLocalLoading(loading: true);
    try {
      return await operation;
    } finally {
      setLocalLoading(loading: false);
    }
  }
}
