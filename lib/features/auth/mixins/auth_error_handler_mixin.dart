import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/widgets/lockout_dialog.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// Mixin that provides consistent error handling across authentication screens.
///
/// This mixin standardizes error display patterns while maintaining support
/// for complex error types like account lockouts.
mixin AuthErrorHandlerMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Handles authentication errors with appropriate UI feedback
  void handleAuthError(AuthStateError error, {String? email}) {
    if (!mounted) return;

    // Check if this is a lockout exception stored in details
    if (error.details is AccountTemporarilyLockedException) {
      final lockoutException =
          error.details as AccountTemporarilyLockedException;
      showLockoutDialog(
        context, 
        lockoutException.timeRemaining,
        email ?? 'unknown@example.com',
      );
    } else {
      showErrorMessage(error.message);
    }
  }

  /// Shows an error message using consistent styling
  void showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Shows a success message using consistent styling
  void showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Sets up auth state listener for error handling
  ///
  /// Call this from initState() to automatically handle auth errors
  void setupAuthErrorListener({String? email}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<AuthState>(
        authProvider, // This will need to be imported
        (previous, next) {
          if (next is AuthStateError) {
            handleAuthError(next, email: email);
          }
        },
      );
    });
  }
}
