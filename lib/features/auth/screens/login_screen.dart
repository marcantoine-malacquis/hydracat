import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/mixins/auth_loading_state_mixin.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/widgets/lockout_dialog.dart';
import 'package:hydracat/features/auth/widgets/social_signin_buttons.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';

/// A screen that handles user authentication and login.
class LoginScreen extends ConsumerStatefulWidget {
  /// Creates a login screen.
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with AuthLoadingStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  ProviderSubscription<AuthState>? _authSubscription;
  bool _isShowingLockoutDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen to auth state changes once (avoid re-registering on rebuilds)
      _authSubscription = ref.listenManual<AuthState>(
        authProvider,
        (previous, next) {
          if (next is AuthStateError) {
            _handleAuthError(next);
          } else {}
        },
        fireImmediately: false,
      );

      // Handle any existing error state immediately after mount
      final current = ref.read(authProvider);
      if (current is AuthStateError) {
        _handleAuthError(current);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (isLocalLoading) {
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setLocalLoading(loading: true);

      try {
        // Clear any existing snackbars before attempting login
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
        }

        await ref
            .read(authProvider.notifier)
            .signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      } finally {
        if (mounted) {
          setLocalLoading(loading: false);
        }
      }
    } else {}
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
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
  }

  void _handleAuthError(AuthStateError authError) {
    if (!mounted) return;

    // Use a post-frame callback to ensure the context is still valid
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Check if this is a lockout exception stored in details
      if (authError.details is AccountTemporarilyLockedException) {
        if (_isShowingLockoutDialog) {
          return;
        }
        _isShowingLockoutDialog = true;
        final lockoutException =
            authError.details as AccountTemporarilyLockedException;
        showLockoutDialog(
          context, 
          lockoutException.timeRemaining,
          _emailController.text.trim(),
        ).whenComplete(
          () {
            _isShowingLockoutDialog = false;
          },
        );
      } else {
        // Show regular error message
        _showErrorSnackBar(authError.message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Uses mixin's isLoading which combines auth and local loading
    ref.watch(authIsLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome back to Hydracat',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'We need your email to continue';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password required to access your account';
                  }
                  if (value.length < 8) {
                    return '8 characters minimum for security';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              HydraButton(
                onPressed: isLoading ? null : _handleSignIn,
                isLoading: isLoading,
                isFullWidth: true,
                child: const Text('Sign In'),
              ),
              const SizedBox(height: AppSpacing.md),

              // Social Sign-In Buttons
              const SocialSignInButtons(),

              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Forgot your password?'),
                  TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text('Reset Password'),
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
