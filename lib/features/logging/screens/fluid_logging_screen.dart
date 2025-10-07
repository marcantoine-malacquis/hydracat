import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/providers/logging_provider.dart';

/// Fluid therapy logging screen (placeholder for Phase 3.3).
///
/// This screen will contain:
/// - Volume input field
/// - Injection site selector
/// - Stress level selector (optional)
/// - Notes field
/// - Log button with validation
///
/// For now, this is a placeholder that demonstrates the popup infrastructure.
class FluidLoggingScreen extends ConsumerWidget {
  /// Creates a [FluidLoggingScreen].
  const FluidLoggingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return LoggingPopupWrapper(
      title: 'Log Fluid Therapy',
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Fluid Therapy Logging Form',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 3.3',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
