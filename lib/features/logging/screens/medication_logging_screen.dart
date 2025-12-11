import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/models/dashboard_logging_context.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/medication_selection_card.dart';
import 'package:hydracat/features/logging/widgets/session_update_dialog.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Medication logging screen with multi-select confirmation.
///
/// Features:
/// - Multi-select medication cards showing name, strength, and dosage
/// - "Select All" button for convenience
/// - Expandable inline dosage adjustment with presets (full/half/skip)
/// - Notes field (max 5 lines, 500 characters)
/// - Loading overlay during batch write
/// - Success animation with haptic feedback
/// - Duplicate detection with dialog
/// - Auto-selection from notification (via initialScheduleId)
/// - Dashboard context support (pre-select + skip action)
class MedicationLoggingScreen extends ConsumerStatefulWidget {
  /// Creates a [MedicationLoggingScreen].
  ///
  /// If [initialScheduleId] is provided, that medication will be
  /// automatically selected when the screen opens (used for notification
  /// deep-linking). If the schedule is not found, the screen opens normally
  /// without any selection.
  ///
  /// If [dashboardContext] is provided, the medication will be pre-selected
  /// and the scheduled time from the context will be used when logging.
  /// When [dashboardContext] is provided, [onSkipFromDashboard] should also
  /// be provided to enable the skip action.
  const MedicationLoggingScreen({
    this.initialScheduleId,
    this.dashboardContext,
    this.onSkipFromDashboard,
    super.key,
  });

  /// Optional schedule ID to pre-select from notification deep-link.
  final String? initialScheduleId;

  /// Optional dashboard context for pre-selecting medication from home screen.
  final DashboardMedicationContext? dashboardContext;

  /// Optional callback for skip action when opened from dashboard.
  ///
  /// Should call DashboardNotifier.skipMedicationTreatment and show success
  /// feedback. Only used when [dashboardContext] is provided.
  final Future<void> Function()? onSkipFromDashboard;

  @override
  ConsumerState<MedicationLoggingScreen> createState() =>
      _MedicationLoggingScreenState();
}

class _MedicationLoggingScreenState
    extends ConsumerState<MedicationLoggingScreen> {
  // Selection state
  final Set<String> _selectedMedicationIds = {};

  // Dosage state - maps medication ID to custom dosage (defaults to scheduled)
  final Map<String, double> _customDosages = {};

  // Expansion state - tracks which medication card is expanded
  String? _expandedMedicationId;

  // Notes controller and focus
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _notesFocusNode = FocusNode();

  // UI state
  LoadingOverlayState _loadingState = LoadingOverlayState.none;
  bool _selectAllPressed = false;

  @override
  void initState() {
    super.initState();
    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to update counter visibility
    });

    // Auto-select medication from dashboard context (takes precedence)
    // or notification deep-link
    final scheduleIdToSelect =
        widget.dashboardContext?.scheduleId ?? widget.initialScheduleId;
    if (scheduleIdToSelect != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoSelectMedication(scheduleIdToSelect);
      });
    }
  }

  /// Auto-select medication from notification deep-link.
  ///
  /// Validates that the schedule exists in today's schedules before selecting.
  /// If not found, logs a warning but does not show any user-facing error
  /// (the screen opens normally and user can select manually).
  void _autoSelectMedication(String scheduleId) {
    final schedules = ref.read(todaysMedicationSchedulesProvider);
    final scheduleExists = schedules.any((s) => s.id == scheduleId);

    if (scheduleExists) {
      setState(() {
        _selectedMedicationIds.add(scheduleId);
      });
      debugPrint(
        '[MedicationLoggingScreen] Auto-selected medication from '
        'notification: $scheduleId',
      );
    } else {
      debugPrint(
        '[MedicationLoggingScreen] ⚠️ Schedule $scheduleId from notification '
        'not found, skipping auto-select',
      );
    }
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Toggle medication selection
  void _toggleMedication(String medicationId) {
    final schedules = ref.read(todaysMedicationSchedulesProvider);
    final schedule = schedules.firstWhere((s) => s.id == medicationId);

    setState(() {
      if (_selectedMedicationIds.contains(medicationId)) {
        _selectedMedicationIds.remove(medicationId);
        // Collapse if this was the expanded card
        if (_expandedMedicationId == medicationId) {
          _expandedMedicationId = null;
        }
      } else {
        _selectedMedicationIds.add(medicationId);
        // Initialize custom dosage to scheduled dose
        _customDosages[medicationId] = schedule.targetDosage ?? 1.0;
        // Selection haptic feedback
        HapticFeedback.selectionClick();
      }
    });
  }

  /// Toggle all medications
  Future<void> _toggleSelectAll(int totalCount) async {
    final schedules = ref.read(todaysMedicationSchedulesProvider);

    setState(() => _selectAllPressed = true);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    setState(() {
      if (_selectedMedicationIds.length == totalCount) {
        // Deselect all
        _selectedMedicationIds.clear();
        _expandedMedicationId = null; // Collapse any expanded card
      } else {
        // Select all
        _selectedMedicationIds.clear();
        for (final schedule in schedules) {
          _selectedMedicationIds.add(schedule.id);
          // Initialize custom dosage to scheduled dose
          _customDosages[schedule.id] = schedule.targetDosage ?? 1.0;
        }
        HapticFeedback.selectionClick();
      }
      _selectAllPressed = false;
    });
  }

  /// Check if form is valid
  bool get _isFormValid {
    // Must have at least one medication selected
    return _selectedMedicationIds.isNotEmpty;
  }

  /// Log all selected medications
  Future<void> _logMedications() async {
    if (!_isFormValid) return;
    // Avoid flicker for very fast operations
    final showLoadingTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _loadingState == LoadingOverlayState.none) {
        setState(() {
          _loadingState = LoadingOverlayState.loading;
        });
      }
    });

    var hasErrors = false;
    try {
      final schedules = ref.read(todaysMedicationSchedulesProvider);
      final user = ref.read(currentUserProvider);
      final pet = ref.read(primaryPetProvider);

      if (user == null || pet == null) {
        final l10n = AppLocalizations.of(context)!;
        _showError(l10n.loggingUserNotFound);
        return;
      }
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text;

      // Log each selected medication
      for (final medicationId in _selectedMedicationIds) {
        final schedule = schedules.firstWhere((s) => s.id == medicationId);

        // Use dashboard context scheduled time if available, otherwise
        // get today's scheduled time for this medication (centralized helper)
        final DateTime scheduledTime;
        if (widget.dashboardContext != null &&
            widget.dashboardContext!.scheduleId == medicationId) {
          // Use the scheduled time from dashboard context
          scheduledTime = widget.dashboardContext!.scheduledTime;
        } else {
          // Fallback to existing logic for notification/FAB flows
          // Use the CLOSEST reminder time to now (not just first) so that
          // the logged session matches the dashboard's expectation
          final now = DateTime.now();
          final todaysReminderTimes = schedule
              .todaysReminderTimes(now)
              .toList();
          if (todaysReminderTimes.isNotEmpty) {
            // Find the closest reminder time to now
            scheduledTime = todaysReminderTimes.reduce((a, b) {
              final diffA = a.difference(now).abs();
              final diffB = b.difference(now).abs();
              return diffA < diffB ? a : b;
            });
          } else {
            scheduledTime = now;
          }
        }

        // Get custom dosage or default to scheduled dosage
        final dosageGiven =
            _customDosages[medicationId] ?? schedule.targetDosage!;

        // Create medication session with custom or scheduled dosage
        final session = MedicationSession.create(
          petId: pet.id,
          userId: user.id,
          dateTime: DateTime.now(),
          medicationName: schedule.medicationName!,
          dosageGiven: dosageGiven,
          dosageScheduled: schedule.targetDosage!,
          medicationUnit: schedule.medicationUnit!,
          medicationStrengthAmount: schedule.medicationStrengthAmount,
          medicationStrengthUnit: schedule.medicationStrengthUnit,
          customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
          completed: dosageGiven > 0, // Completed if dosage > 0, missed if 0
          notes: notes,
          scheduleId: schedule.id,
          scheduledTime: scheduledTime,
        );

        // Log the session
        final success = await ref
            .read(loggingProvider.notifier)
            .logMedicationSession(
              session: session,
              todaysSchedules: schedules,
            );

        if (!success) {
          hasErrors = true;
          // Check if it's a duplicate error by looking at the provider's state
          // The error is stored in loggingErrorProvider after being caught
          final error = ref.read(loggingErrorProvider);
          if (error != null && error.contains('already logged')) {
            // Duplicate detected - prepare dialog data BEFORE closing popup
            if (mounted) {
              // Get all the data we need while ref is still valid
              final schedules = ref.read(todaysMedicationSchedulesProvider);
              final medicationSchedule = schedules.firstWhere(
                (s) => s.medicationName == schedule.medicationName,
              );
              final user = ref.read(currentUserProvider);
              final pet = ref.read(primaryPetProvider);
              final notes = _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text;

              // Capture a stable NavigatorState BEFORE closing overlay
              final navigator = Navigator.of(context, rootNavigator: true);

              // Close the medication logging popup
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }

              // Wait a frame for popup to close
              await Future<void>.delayed(const Duration(milliseconds: 100));

              // Show duplicate dialog (guard against disposed navigator)
              if (user != null && pet != null && navigator.mounted) {
                await _showDuplicateDialogWithData(
                  navigator: navigator,
                  medicationName: schedule.medicationName!,
                  medicationSchedule: medicationSchedule,
                  user: user,
                  pet: pet,
                  notes: notes,
                );
              }
            }
          }
          break; // Stop on first error
        }
      }

      if (!hasErrors) {
        if (showLoadingTimer.isActive) {
          showLoadingTimer.cancel();
        }

        if (!mounted) return;

        // Capture stable references before closing the sheet
        final rootNavigator = Navigator.of(context, rootNavigator: true);
        final l10n = AppLocalizations.of(context)!;
        final successMessage = l10n.medicationLogged;

        // Reset state and close popup
        ref.read(loggingProvider.notifier).reset();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Show success snackbar after popup has closed
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (rootNavigator.mounted) {
          HydraSnackBar.showSuccess(
            rootNavigator.context,
            successMessage,
          );
        }
      }
    } finally {
      showLoadingTimer.cancel();
      if (mounted && hasErrors) {
        // Only reset state if there were errors
        // (success state is handled above)
        setState(() {
          _loadingState = LoadingOverlayState.none;
        });
      }
    }
  }

  /// Show duplicate session dialog with pre-fetched data
  ///
  /// This method is called after the popup is dismissed, so it doesn't use
  /// ref (which would be disposed). All data is passed as parameters.
  Future<void> _showDuplicateDialogWithData({
    required NavigatorState navigator,
    required String medicationName,
    required Schedule medicationSchedule,
    required AppUser user,
    required CatProfile pet,
    required String? notes,
  }) async {
    // Get today's scheduled time for this medication (centralized helper)
    final now = DateTime.now();
    final todaysReminderTimes = medicationSchedule
        .todaysReminderTimes(now)
        .toList();

    // Use the CLOSEST reminder time to now (not just first)
    // If no reminder time for today, use current time as fallback
    final DateTime scheduledTime;
    if (todaysReminderTimes.isNotEmpty) {
      scheduledTime = todaysReminderTimes.reduce((a, b) {
        final diffA = a.difference(now).abs();
        final diffB = b.difference(now).abs();
        return diffA < diffB ? a : b;
      });
    } else {
      scheduledTime = now;
    }

    // Create a mock existing session (this will be replaced with actual
    // data from the exception in Phase 5)
    final mockExistingSession = MedicationSession.create(
      petId: pet.id,
      userId: user.id,
      dateTime: DateTime.now().subtract(const Duration(minutes: 5)),
      medicationName: medicationName,
      dosageGiven: medicationSchedule.targetDosage!,
      dosageScheduled: medicationSchedule.targetDosage!,
      medicationUnit: medicationSchedule.medicationUnit!,
      medicationStrengthAmount: medicationSchedule.medicationStrengthAmount,
      medicationStrengthUnit: medicationSchedule.medicationStrengthUnit,
      customMedicationStrengthUnit:
          medicationSchedule.customMedicationStrengthUnit,
      completed: true,
      scheduleId: medicationSchedule.id,
      scheduledTime: scheduledTime,
    );

    // Create the new session from current form state
    final newSession = MedicationSession.create(
      petId: pet.id,
      userId: user.id,
      dateTime: DateTime.now(),
      medicationName: medicationName,
      dosageGiven: medicationSchedule.targetDosage!,
      dosageScheduled: medicationSchedule.targetDosage!,
      medicationUnit: medicationSchedule.medicationUnit!,
      medicationStrengthAmount: medicationSchedule.medicationStrengthAmount,
      medicationStrengthUnit: medicationSchedule.medicationStrengthUnit,
      customMedicationStrengthUnit:
          medicationSchedule.customMedicationStrengthUnit,
      completed: true,
      notes: notes,
      scheduleId: medicationSchedule.id,
      scheduledTime: scheduledTime,
    );

    // Use the saved navigator context instead of widget context
    await showDialog<void>(
      context: navigator.context,
      builder: (context) => SessionUpdateDialog(
        existingSession: mockExistingSession,
        newSession: newSession,
      ),
    );
  }

  /// Handle skip action when opened from dashboard
  Future<void> _handleSkip() async {
    if (widget.onSkipFromDashboard == null) return;

    try {
      // Show loading state
      setState(() {
        _loadingState = LoadingOverlayState.loading;
      });

      // Call the skip callback (which handles dashboard state and analytics)
      await widget.onSkipFromDashboard!();

      // Close the bottom sheet on success
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      // Show error if skip fails
      if (mounted) {
        setState(() {
          _loadingState = LoadingOverlayState.none;
        });
        _showError('Failed to skip medication: $e');
      }
    }
  }

  /// Show error message using centralized error handler
  void _showError(String message) {
    if (!mounted) return;
    LoggingErrorHandler.showLoggingError(context, message);
    // Announce to screen readers
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final schedules = ref.watch(todaysMedicationSchedulesProvider);

    return LoggingPopupWrapper(
      title: l10n.medicationLoggingTitle,
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: LoadingOverlay(
        state: _loadingState,
        loadingMessage: l10n.medicationLoggingLoadingMessage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Select All button (if multiple medications)
            if (schedules.length > 1) ...[
              AnimatedScale(
                scale: _selectAllPressed ? 0.95 : 1.0,
                duration: AppAnimations.getDuration(
                  context,
                  const Duration(milliseconds: 100),
                ),
                curve: Curves.easeInOut,
                child: OutlinedButton(
                  onPressed: _loadingState != LoadingOverlayState.none
                      ? null
                      : () => _toggleSelectAll(
                          schedules.length,
                        ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                  child: Text(
                    _selectedMedicationIds.length == schedules.length
                        ? l10n.medicationDeselectAll
                        : l10n.medicationSelectAll,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Medication selection section
            Text(
              l10n.medicationSelectLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Medication cards (grid if multiple)
            if (schedules.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  l10n.medicationNoneScheduled,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...schedules.map((schedule) {
                final isSelected = _selectedMedicationIds.contains(schedule.id);
                final isExpanded = _expandedMedicationId == schedule.id;
                final currentDosage =
                    _customDosages[schedule.id] ?? schedule.targetDosage ?? 1.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MedicationSelectionCard(
                    medication: schedule,
                    isSelected: isSelected,
                    isExpanded: isExpanded,
                    currentDosage: currentDosage,
                    onTap: _loadingState != LoadingOverlayState.none
                        ? () {}
                        : () => _toggleMedication(schedule.id),
                    onExpandToggle: () {
                      setState(() {
                        if (_expandedMedicationId == schedule.id) {
                          _expandedMedicationId = null;
                        } else {
                          _expandedMedicationId = schedule.id;
                        }
                      });
                    },
                    onDosageChanged: (double newDosage) {
                      setState(() {
                        _customDosages[schedule.id] = newDosage;
                      });
                    },
                  ),
                );
              }),

            // Notes field (appears right after medication selection)
            const SizedBox(height: AppSpacing.lg),
            HydraTextField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              maxLength: 500,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.loggingNotesLabel,
                hintText: l10n.loggingNotesHintTreatment,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                counter: AnimatedOpacity(
                  opacity: _notesFocusNode.hasFocus ? 1.0 : 0.0,
                  duration: AppAnimations.getDuration(
                    context,
                    const Duration(milliseconds: 200),
                  ),
                  child: Text('${_notesController.text.length}/500'),
                ),
              ),
              // Expand to 5 lines when focused
              onTap: () {
                setState(() {
                  // TextField will expand when tapped
                });
              },
              onChanged: (String value) {
                // Rebuild to show expanded field and update counter
                if (value.isNotEmpty && _notesController.text.length == 1) {
                  setState(() {});
                } else {
                  setState(() {}); // Update counter
                }
              },
              // Show as multiline when has content
              minLines: _notesController.text.isNotEmpty ? 3 : 1,
              maxLines: 5,
            ),

            // Skip button (only shown when opened from dashboard)
            if (widget.dashboardContext != null &&
                widget.onSkipFromDashboard != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                label: 'Skip this dose',
                hint: 'Skip logging this medication dose',
                button: true,
                child: TextButton(
                  onPressed: _loadingState != LoadingOverlayState.none
                      ? null
                      : _handleSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  child: Text(
                    'Skip this dose',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Log button (at bottom for better thumb reach)
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: l10n.medicationLogButton,
              hint: _selectedMedicationIds.length == 1
                  ? l10n.medicationLogButtonSemanticSingle
                  : l10n.medicationLogButtonSemanticMultiple(
                      _selectedMedicationIds.length,
                    ),
              button: true,
              child: FilledButton(
                onPressed:
                    _isFormValid && _loadingState == LoadingOverlayState.none
                    ? _logMedications
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _selectedMedicationIds.length == 1
                      ? l10n.medicationLogButton
                      : l10n.medicationLogButtonMultiple(
                          _selectedMedicationIds.length,
                        ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
