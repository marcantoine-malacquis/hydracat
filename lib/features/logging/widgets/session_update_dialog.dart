import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return HydraAlertDialog(
      title: Text(l10n.duplicateDialogTitle),
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
              style: theme.textTheme.bodyMedium,
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
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.duplicateDialogSummaryWarning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
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
          child: Text(l10n.cancel),
        ),

        // Create New button (secondary)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.duplicateDialogCreateNewMessage),
              ),
            );
          },
          child: Text(l10n.duplicateDialogCreateNew),
        ),

        // Update button (primary)
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.duplicateDialogUpdateMessage),
              ),
            );
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.3,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card title
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          if (isExisting) ...[
            const SizedBox(height: 2),
            Text(
              l10n.duplicateDialogLoggedAt(_formatTime(session.dateTime)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);

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
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
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
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: hasChanged
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: hasChanged
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasChanged) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: theme.colorScheme.primary,
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
