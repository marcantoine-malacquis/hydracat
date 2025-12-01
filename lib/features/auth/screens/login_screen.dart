import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/auth/exceptions/auth_exceptions.dart';
import 'package:hydracat/features/auth/mixins/auth_loading_state_mixin.dart';
import 'package:hydracat/features/auth/models/auth_state.dart';
import 'package:hydracat/features/auth/widgets/lockout_dialog.dart';
import 'package:hydracat/features/auth/widgets/social_signin_buttons.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

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
  bool _isShowingLockoutDialog = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
      HydraSnackBar.showError(context, message);
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
    // Listen to auth state changes using built-in Riverpod mechanism
    ref
      ..listen<AuthState>(authProvider, (previous, next) {
        if (next is AuthStateError) {
          _handleAuthError(next);
        }
      })
      // Uses mixin's isLoading which combines auth and local loading
      ..watch(authIsLoadingProvider);

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive logo sizing: 120-140-160dp
                    // scale up for larger screens
                    final screenHeight = MediaQuery.of(context).size.height;
                    final logoHeight = screenHeight < 600
                        ? 120.0
                        : screenHeight < 900
                        ? 140.0
                        : 160.0;

                    return Center(
                      child: SizedBox(
                        height: logoHeight,
                        width:
                            logoHeight *
                            (243.985 / 310.892), // Maintain aspect ratio
                        child: SvgPicture.asset(
                          'assets/branding/official_logo.svg',
                          semanticsLabel: 'Hydracat logo',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Welcome back to Hydracat',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HydraTextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
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
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    HydraTextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.border,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.error,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        suffixIcon: IconButton(
                          icon: HydraIcon(
                            icon: _obscurePassword
                                ? AppIcons.visibility
                                : AppIcons.visibilityOff,
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
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => context.go('/forgot-password'),
                      child: Text(
                        'Forgot your password?',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                HydraButton(
                  onPressed: isLoading ? null : _handleSignIn,
                  isLoading: isLoading,
                  isFullWidth: true,
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Social Sign-In Buttons
                const SocialSignInButtons(),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    HydraButton(
                      onPressed: () => context.go('/register'),
                      variant: HydraButtonVariant.text,
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
