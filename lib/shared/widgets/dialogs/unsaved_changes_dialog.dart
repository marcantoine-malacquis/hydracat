import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';

/// A dialog that prompts users to save or discard unsaved changes.
///
/// This dialog is shown when a user tries to navigate away from a screen
/// with unsaved changes. It provides two options:
/// - Save changes: Saves the changes and navigates away
/// - Discard: Discards changes and navigates away
///
/// The dialog is displayed using [OverlayService] for consistent blur
/// background with other app popups.
///
/// Usage:
/// ```dart
/// UnsavedChangesDialog.show(
///   context: context,
///   onSave: () async {
///     await saveChanges();
///     context.pop();
///   },
///   onDiscard: () {
///     context.pop();
///   },
/// );
/// ```
class UnsavedChangesDialog extends StatelessWidget {
  /// Creates an [UnsavedChangesDialog].
  const UnsavedChangesDialog({
    required this.onSave,
    required this.onDiscard,
    super.key,
  });

  /// Callback when user chooses to save changes.
  ///
  /// Should typically save the changes and then navigate away.
  final VoidCallback onSave;

  /// Callback when user chooses to discard changes.
  ///
  /// Should typically navigate away without saving.
  final VoidCallback onDiscard;

  /// Shows the unsaved changes dialog using [OverlayService].
  ///
  /// Parameters:
  /// - [context]: Build context for overlay insertion
  /// - [onSave]: Callback when user taps "Save changes"
  /// - [onDiscard]: Callback when user taps "Discard"
  static void show({
    required BuildContext context,
    required VoidCallback onSave,
    required VoidCallback onDiscard,
  }) {
    OverlayService.showFullScreenPopup(
      context: context,
      child: UnsavedChangesDialog(
        onSave: onSave,
        onDiscard: onDiscard,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  'Do you want to save the changes?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Action buttons
                Row(
                  children: [
                    // Discard button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          OverlayService.hide();
                          onDiscard();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.outline,
                            width: 1.5,
                          ),
                        ),
                        child: const Text('Discard'),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Save changes button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          OverlayService.hide();
                          onSave();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
