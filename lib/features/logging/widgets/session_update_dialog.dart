import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_shadows.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

/// Dialog shown when attempting to log a duplicate medication session
///
/// Displays:
/// - Comparison of existing vs new session values (only changed fields)
/// - Warning about summary adjustments (conditional)
/// - Actions: Cancel, Create New, Update Existing (primary)
///
/// Usage:
/// ```dart
/// await showDialog<SessionUpdateAction>(
///   context: context,
///   builder: (_) => SessionUpdateDialog(
///     existingSession: existingSession,
///     newSession: newSession,
///   ),
/// );
/// ```
class SessionUpdateDialog extends StatelessWidget {
  /// Creates a [SessionUpdateDialog]
  const SessionUpdateDialog({
    required this.existingSession,
    required this.newSession,
    super.key,
  });

  /// The existing session that was already logged
  final MedicationSession existingSession;

  /// The new session the user is attempting to log
  final MedicationSession newSession;

  /// Format time for display (e.g., "8:30 AM")
  String _formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Check if dosage changed
  bool get _dosageChanged =>
      existingSession.dosageGiven != newSession.dosageGiven;

  /// Check if completed status changed
  bool get _completedChanged =>
      existingSession.completed != newSession.completed;

  /// Check if notes changed
  bool get _notesChanged => existingSession.notes != newSession.notes;

  /// Check if any field changed
  bool get _hasChanges => _dosageChanged || _completedChanged || _notesChanged;

  /// Check if summary will be affected
  bool get _summaryAffected => _dosageChanged || _completedChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final maxDialogWidth = screenWidth * 0.9; // 90% of screen width

    return HydraAlertDialog(
      title: Text(
        l10n.duplicateDialogTitle,
        style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.lg,
      ),
      constraints: BoxConstraints(
        maxWidth: maxDialogWidth,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header message
            Text(
              l10n.duplicateDialogMessage(
                existingSession.medicationName,
                _formatTime(existingSession.dateTime),
              ),
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Current session card
            _buildSessionCard(
              context: context,
              l10n: l10n,
              title: l10n.duplicateDialogCurrentSession,
              session: existingSession,
              isExisting: true,
            ),

            const SizedBox(height: AppSpacing.md),

            // New session card
            _buildSessionCard(
              context: context,
              l10n: l10n,
              title: l10n.duplicateDialogNewEntry,
              session: newSession,
              isExisting: false,
            ),

            // Summary warning (conditional)
            if (_summaryAffected) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  boxShadow: const [AppShadows.card],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.duplicateDialogSummaryWarning,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
          ),
          child: Text(l10n.cancel),
        ),

        // Create New button (secondary)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            HydraSnackBar.showInfo(
              context,
              l10n.duplicateDialogCreateNewMessage,
            );
          },
          child: Text(l10n.duplicateDialogCreateNew),
        ),

        // Update button (primary)
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            HydraSnackBar.showInfo(context, l10n.duplicateDialogUpdateMessage);
          },
          child: Text(l10n.duplicateDialogUpdate),
        ),
      ],
    );
  }

  /// Build a session comparison card
  Widget _buildSessionCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required String title,
    required MedicationSession session,
    required bool isExisting,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: const [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Text(
            title,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isExisting) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.duplicateDialogLoggedAt(_formatTime(session.dateTime)),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),

          // Field rows (only show changed fields or all if nothing changed)
          if (!_hasChanges || _dosageChanged)
            _buildFieldRow(
              context: context,
              label: l10n.duplicateDialogDosage,
              value: '${session.dosageGiven} ${session.medicationUnit}',
              hasChanged: _dosageChanged && !isExisting,
            ),

          if (!_hasChanges || _completedChanged)
            _buildFieldRow(
              context: context,
              label: l10n.duplicateDialogStatus,
              value: session.completed
                  ? l10n.duplicateDialogStatusCompleted
                  : l10n.duplicateDialogStatusNotCompleted,
              hasChanged: _completedChanged && !isExisting,
            ),

          if (!_hasChanges || _notesChanged)
            _buildFieldRow(
              context: context,
              label: l10n.duplicateDialogNotes,
              value: (session.notes?.isNotEmpty ?? false)
                  ? session.notes!
                  : l10n.duplicateDialogNoNotes,
              hasChanged: _notesChanged && !isExisting,
            ),
        ],
      ),
    );
  }

  /// Build a field row with label and value
  Widget _buildFieldRow({
    required BuildContext context,
    required String label,
    required String value,
    required bool hasChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Value
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: hasChanged
                        ? AppTextStyles.clinicalData.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          )
                        : AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                  ),
                ),
                if (hasChanged) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.edit,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
