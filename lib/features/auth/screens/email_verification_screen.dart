import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/mixins/auth_error_handler_mixin.dart';
import 'package:hydracat/features/auth/mixins/auth_loading_state_mixin.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Configuration for smart email verification polling
class VerificationPollingConfig {
  /// Initial delay between verification checks
  static const Duration initialDelay = Duration(seconds: 5);

  /// Maximum delay between verification checks
  static const Duration maxDelay = Duration(minutes: 1);

  /// Maximum consecutive failures before circuit breaker
  static const int maxFailures = 3;

  /// Delay during circuit breaker activation
  static const Duration circuitBreakerDelay = Duration(minutes: 5);

  /// Maximum time to continue polling before timeout
  static const Duration maxPollingDuration = Duration(minutes: 10);

  /// Multiplier for exponential backoff
  static const int backoffMultiplier = 2;
}

/// A screen that handles email verification for new user accounts.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  /// Creates an email verification screen.
  const EmailVerificationScreen({
    required this.email,
    super.key,
  });

  /// The user's email address
  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with AuthErrorHandlerMixin, AuthLoadingStateMixin {
  bool _isResendCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _verificationCheckTimer;

  // Smart polling state
  Duration _currentDelay = VerificationPollingConfig.initialDelay;
  int _failureCount = 0;
  DateTime? _pollingStartTime;
  bool _isPollingActive = false;
  String _pollingStatus = '';

  @override
  void initState() {
    super.initState();
    _startVerificationPolling();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _verificationCheckTimer?.cancel();
    super.dispose();
  }

  void _startVerificationPolling() {
    _currentDelay = VerificationPollingConfig.initialDelay;
    _failureCount = 0;
    _pollingStartTime = DateTime.now();
    _isPollingActive = true;
    if (mounted) {
      setState(() {
        _pollingStatus = 'Checking verification...';
      });
    }
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    if (!_isPollingActive || !mounted) return;

    // Stop if maximum duration exceeded
    if (_pollingStartTime != null &&
        DateTime.now().difference(_pollingStartTime!) >
            VerificationPollingConfig.maxPollingDuration) {
      _handlePollingTimeout();
      return;
    }

    // Schedule next check with current delay
    _verificationCheckTimer = Timer(_currentDelay, _performSmartCheck);
  }

  Future<void> _performSmartCheck() async {
    if (!mounted || !_isPollingActive) return;

    try {
      final isVerified = await ref
          .read(authProvider.notifier)
          .checkEmailVerification();

      if (isVerified && mounted) {
        // Success - stop polling and navigate
        _stopPolling();
        context.go('/');
        return;
      }

      // Reset failure count on successful check (even if not verified yet)
      _failureCount = 0;

      // Increase delay for next check (exponential backoff)
      _currentDelay = Duration(
        milliseconds:
            _currentDelay.inMilliseconds *
            VerificationPollingConfig.backoffMultiplier,
      );

      // Clamp to max delay
      if (_currentDelay > VerificationPollingConfig.maxDelay) {
        _currentDelay = VerificationPollingConfig.maxDelay;
      }

      if (mounted) {
        setState(() {
          _pollingStatus = 'Next check in ${_formatDuration(_currentDelay)}';
        });
      }
    } on Exception catch (_) {
      _handlePollingFailure();
    }

    _scheduleNextCheck();
  }

  void _handlePollingFailure() {
    _failureCount++;

    if (_failureCount >= VerificationPollingConfig.maxFailures) {
      // Trigger circuit breaker
      _currentDelay = VerificationPollingConfig.circuitBreakerDelay;
      _failureCount = 0; // Reset for next attempt

      if (mounted) {
        setState(() {
          _pollingStatus =
              'Connection issues. '
              'Trying again in ${_formatDuration(_currentDelay)}';
        });
      }
    }
  }

  void _handlePollingTimeout() {
    _stopPolling();
    if (mounted) {
      setState(() {
        _pollingStatus =
            'Verification check timed out. '
            'Try resending the email or check manually.';
      });
    }
  }

  void _stopPolling() {
    _isPollingActive = false;
    _verificationCheckTimer?.cancel();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Future<void> _checkVerificationStatus() async {
    // Manual check - reset polling with fresh start
    _stopPolling();
    _startVerificationPolling();
  }

  Future<void> _sendVerificationEmail() async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.sendEmailVerification();

    if (result is AuthSuccess && mounted) {
      showSuccessMessage('Verification email sent to ${widget.email}');
      _startResendCooldown();
      // Reset polling with fresh start after sending new email
      _stopPolling();
      _startVerificationPolling();
    } else if (result is AuthFailure && mounted) {
      showErrorMessage(result.message);
    }
  }

  void _startResendCooldown() {
    setState(() {
      _isResendCooldown = true;
      _cooldownSeconds = 30;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _cooldownSeconds--;
      });

      if (_cooldownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isResendCooldown = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<AuthState>(authProvider, (previous, next) {
        if (next is AuthStateError) {
          handleAuthError(next, email: widget.email);
        }
      })
      ..watch(authProvider);

    return Scaffold(
      appBar: const HydraAppBar(
        title: Text('Verify Your Email'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.mark_email_unread_outlined,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Account Verification Required',
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Account verification is required to protect your data',
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'A verification link will be sent to:',
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    widget.email,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            HydraButton(
              onPressed: isLoading || _isResendCooldown
                  ? null
                  : _sendVerificationEmail,
              isLoading: isLoading,
              isFullWidth: true,
              child: Text(
                _isResendCooldown
                    ? 'Resend in ${_cooldownSeconds}s'
                    : 'Send Verification Email',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'After clicking the verification link in your email, you will be '
              'automatically redirected to the app.',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              "Check your spam folder if you don't see the email.",
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            // Smart polling status display
            if (_pollingStatus.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _isPollingActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isPollingActive) ...[
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: HydraProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        _pollingStatus,
                        style: AppTextStyles.caption.copyWith(
                          color: _isPollingActive
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            if (_pollingStatus.isNotEmpty)
              const SizedBox(height: AppSpacing.md),
            // Manual check button when polling stops
            if (!_isPollingActive && _pollingStatus.isNotEmpty)
              TextButton(
                onPressed: _checkVerificationStatus,
                child: const Text('Check Again'),
              ),
            const SizedBox(height: AppSpacing.xl),
            TextButton(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
                context.go('/login');
              },
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
