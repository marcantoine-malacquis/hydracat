import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/providers/auth_provider.dart';

/// A widget that provides Google and Apple Sign-In buttons
///
/// Handles social authentication with proper loading states and error handling.
/// Apple Sign-In is only shown on iOS platforms.
class SocialSignInButtons extends ConsumerStatefulWidget {
  /// Creates a social sign-in buttons widget
  const SocialSignInButtons({super.key});

  @override
  ConsumerState<SocialSignInButtons> createState() =>
      _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends ConsumerState<SocialSignInButtons> {
  Future<void> _handleGoogleSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithGoogle();
    } on Exception {
      // Error handling is managed by the auth provider
      // Any errors will be shown through the auth state listener
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await ref.read(authProvider.notifier).signInWithApple();
    } on Exception {
      // Error handling is managed by the auth provider
      // Any errors will be shown through the auth state listener
    }
  }

  /// Check if Apple Sign-In should be shown
  bool get _shouldShowAppleSignIn {
    // Show on iOS or when debugging on other platforms
    return !kIsWeb && (Platform.isIOS || kDebugMode);
  }

  @override
  Widget build(BuildContext context) {
    final isAuthLoading = ref.watch(authIsLoadingProvider);

    return Column(
      children: [
        // Divider with "OR" text
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Google Sign-In Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: isAuthLoading ? null : _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isAuthLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Google logo SVG (following official branding)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CustomPaint(
                          painter: GoogleLogoPainter(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Apple Sign-In Button (iOS only)
        if (_shouldShowAppleSignIn) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: isAuthLoading ? null : _handleAppleSignIn,
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.black,
                side: const BorderSide(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isAuthLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apple,
                          size: 18,
                          color: Colors.white,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Continue with Apple',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for Google logo following official branding guidelines
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Scale the logo to fit the given size
    final scaleX = size.width / 48.0;
    final scaleY = size.height / 48.0;
    
    canvas.scale(scaleX, scaleY);

    // Google "G" logo paths (official colors)
    
    // Red path
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0, 24, 0)
      ..cubicTo(14.62, 0, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24, 9.5)
      ..close();
    canvas.drawPath(redPath, paint);

    // Blue path
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20)
      ..lineTo(24, 20)
      ..lineTo(24, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Yellow path
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24)
      ..cubicTo(9.77, 22.4, 10.04, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0, 20.12, 0, 24)
      ..cubicTo(0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Green path
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24, 48)
      ..cubicTo(30.48, 48, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48, 24, 48)
      ..close();
    canvas.drawPath(greenPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
