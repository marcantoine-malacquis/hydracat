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
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

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
    _verificationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerificationStatus(),
    );
  }

  Future<void> _checkVerificationStatus() async {
    final isVerified = await ref
        .read(authProvider.notifier)
        .checkEmailVerification();
    if (isVerified && mounted) {
      _verificationCheckTimer?.cancel();
      context.go('/');
    }
  }

  Future<void> _sendVerificationEmail() async {
    final authService = ref.read(authServiceProvider);
    final result = await authService.sendEmailVerification();

    if (result is AuthSuccess && mounted) {
      showSuccessMessage('Verification email sent to ${widget.email}');
      _startResendCooldown();
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
          handleAuthError(next);
        }
      })
      ..watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Email'),
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
