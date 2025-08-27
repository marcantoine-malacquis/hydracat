import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/services/auth_service.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// A screen that allows users to reset their password via email.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  /// Creates a forgot password screen.
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordReset() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = AuthService();
        final result = await authService.sendPasswordResetEmail(
          _emailController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
            _emailSent = result is AuthSuccess;
          });

          if (result is AuthSuccess) {
            _showSuccessSnackBar();
          } else if (result is AuthFailure) {
            _showErrorSnackBar(result.message);
          }
        }
      } on Exception {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showErrorSnackBar('An error occurred. Please try again.');
        }
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password reset email sent! Please check your inbox.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Reset Your Password',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _emailSent
                    ? "We've sent reset instructions to your email. "
                          'Check your inbox and follow the link to create a '
                          "new password for your cat's treatment account."
                    : "Enter your email address and we'll help you regain "
                          "access to your cat's treatment data.",
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!_emailSent) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                    helperText:
                        'Enter the email address associated with your account',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                HydraButton(
                  onPressed: _isLoading ? null : _handlePasswordReset,
                  isLoading: _isLoading,
                  isFullWidth: true,
                  child: const Text('Send Reset Email'),
                ),
              ] else ...[
                const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: AppSpacing.lg),
                HydraButton(
                  onPressed: () => setState(() {
                    _emailSent = false;
                    _emailController.clear();
                  }),
                  isFullWidth: true,
                  child: const Text('Send Another Email'),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Remember your password?'),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
