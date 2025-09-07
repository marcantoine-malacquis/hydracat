import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dialog shown when account is temporarily locked due to too many failed
/// attempts
class LockoutDialog extends StatefulWidget {
  /// Creates a [LockoutDialog] with the given lockout duration
  const LockoutDialog({
    required this.timeRemaining,
    super.key,
  });

  /// Time remaining until the account is unlocked
  final Duration timeRemaining;

  @override
  State<LockoutDialog> createState() => _LockoutDialogState();
}

class _LockoutDialogState extends State<LockoutDialog> {
  late Duration _timeRemaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timeRemaining;
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          // Auto-close dialog when lockout expires
          context.pop();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      }
    });
  }

  String _formatTimeRemaining() {
    final hours = _timeRemaining.inHours;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.lock_clock,
        color: theme.colorScheme.error,
        size: 32,
      ),
      title: Text(
        'Account Temporarily Locked',
        style: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Too many failed login attempts have been detected. '
            'This is a security measure to protect your account.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Time Remaining',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTimeRemaining(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can reset your password or wait for the lockout to expire.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context
              ..pop()
              // Navigate to forgot password screen
              ..push('/forgot-password');
          },
          child: const Text('Reset Password'),
        ),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

/// Shows a lockout dialog with the given time remaining
Future<void> showLockoutDialog(
  BuildContext context,
  Duration timeRemaining,
) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return LockoutDialog(timeRemaining: timeRemaining);
    },
  );
}
