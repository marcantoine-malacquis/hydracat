import 'package:flutter/material.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// A card displaying medication summary information
class MedicationSummaryCard extends StatelessWidget {
  /// Creates a [MedicationSummaryCard]
  const MedicationSummaryCard({
    required this.medication,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    super.key,
  });

  /// The medication data to display
  final MedicationData medication;

  /// Callback when the card is tapped
  final VoidCallback? onTap;

  /// Callback when edit button is pressed
  final VoidCallback? onEdit;

  /// Callback when delete button is pressed
  final VoidCallback? onDelete;

  /// Whether to show action buttons (edit/delete)
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Medication icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getMedicationIcon(),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Medication name
                  Expanded(
                    child: Text(
                      medication.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // Action buttons
                  if (showActions) ...[
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: l10n.editMedicationTooltip,
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: l10n.deleteMedicationTooltip,
                      ),
                  ],
                ],
              ),

              const SizedBox(height: 12),

              // Medication summary
              Text(
                medication.summary,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),

              // Compact reminders row on a single line
              if (medication.reminderTimes.isNotEmpty)
                Row(
                  children: [
                    // Left: bell + count
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${medication.reminderTimes.length} reminder'
                      '${medication.reminderTimes.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right: reminder time chips (max 3, with +N)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                _buildCompactReminderChips(
                                      context,
                                      theme,
                                    )
                                    .expand(
                                      (w) => [w, const SizedBox(width: 6)],
                                    )
                                    .toList()
                                  ..removeLast(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMedicationIcon() {
    return switch (medication.unit) {
      MedicationUnit.pills => Icons.medication,
      MedicationUnit.capsules => Icons.medication,
      MedicationUnit.drops => Icons.water_drop,
      MedicationUnit.injections => Icons.colorize,
      MedicationUnit.milliliters => Icons.local_drink,
      MedicationUnit.tablespoon => Icons.restaurant,
      MedicationUnit.teaspoon => Icons.restaurant,
      MedicationUnit.portions => Icons.restaurant,
      MedicationUnit.sachets => Icons.inventory_2,
      MedicationUnit.ampoules => Icons.science,
      _ => Icons.medication,
    };
  }

  // Removed old _buildReminderTimes; logic moved to _buildCompactReminderChips

  Widget _buildTimeChip(BuildContext context, DateTime time, ThemeData theme) {
    final timeOfDay = TimeOfDay.fromDateTime(time);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        timeOfDay.format(context),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<Widget> _buildCompactReminderChips(
    BuildContext context,
    ThemeData theme,
  ) {
    return medication.reminderTimes
        .map((t) => _buildTimeChip(context, t, theme))
        .toList();
  }
}

/// Empty state widget for when no medications are added
class EmptyMedicationState extends StatelessWidget {
  /// Creates an [EmptyMedicationState]
  const EmptyMedicationState({
    this.onAddMedication,
    super.key,
  });

  /// Callback when add medication button is pressed
  final VoidCallback? onAddMedication;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.medication_outlined,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),

          Text(
            'No medications added',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Add your first medication to get started with your treatment '
            'schedule.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          if (onAddMedication != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddMedication,
              icon: const Icon(Icons.add),
              label: Text(l10n.addMedication),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state widget for medication operations
class MedicationLoadingCard extends StatelessWidget {
  /// Creates a [MedicationLoadingCard]
  const MedicationLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const CircularProgressIndicator(),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 120,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
