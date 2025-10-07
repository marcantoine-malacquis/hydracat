import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/providers/logging_provider.dart';

/// Medication logging screen (placeholder for Phase 3.2).
///
/// This screen will contain:
/// - Medication selection list (multi-select)
/// - Dosage inputs for each selected medication
/// - Notes field
/// - Log button with validation
///
/// For now, this is a placeholder that demonstrates the popup infrastructure.
class MedicationLoggingScreen extends ConsumerWidget {
  /// Creates a [MedicationLoggingScreen].
  const MedicationLoggingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return LoggingPopupWrapper(
      title: 'Log Medication',
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Medication Logging Form',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming in Phase 3.2',
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
