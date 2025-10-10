import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/auth/models/app_user.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/models/medication_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/medication_selection_card.dart';
import 'package:hydracat/features/logging/widgets/session_update_dialog.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/loading/loading_overlay.dart';

/// Medication logging screen with multi-select confirmation.
///
/// Features:
/// - Multi-select medication cards showing name, strength, and dosage
/// - "Select All" button for convenience
/// - Fixed dosage from schedule (no adjustment in this flow)
/// - Notes field (max 5 lines, 500 characters)
/// - Loading overlay during batch write
/// - Success animation with haptic feedback
/// - Duplicate detection with dialog
class MedicationLoggingScreen extends ConsumerStatefulWidget {
  /// Creates a [MedicationLoggingScreen].
  const MedicationLoggingScreen({super.key});

  @override
  ConsumerState<MedicationLoggingScreen> createState() =>
      _MedicationLoggingScreenState();
}

class _MedicationLoggingScreenState
    extends ConsumerState<MedicationLoggingScreen> {
  // Selection state
  final Set<String> _selectedMedicationIds = {};

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
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Toggle medication selection
  void _toggleMedication(String medicationId) {
    setState(() {
      if (_selectedMedicationIds.contains(medicationId)) {
        _selectedMedicationIds.remove(medicationId);
      } else {
        _selectedMedicationIds.add(medicationId);
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
      } else {
        // Select all
        _selectedMedicationIds.clear();
        for (final schedule in schedules) {
          _selectedMedicationIds.add(schedule.id);
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
        _showError('User or pet not found. Please try again.');
        return;
      }
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text;

      // Log each selected medication
      for (final medicationId in _selectedMedicationIds) {
        final schedule = schedules.firstWhere((s) => s.id == medicationId);

        // Get today's scheduled time for this medication
        final now = DateTime.now();
        final todaysReminderTimes = schedule.reminderTimes.where((
          reminderTime,
        ) {
          final reminderDate = DateTime(
            reminderTime.year,
            reminderTime.month,
            reminderTime.day,
          );
          final today = DateTime(now.year, now.month, now.day);
          return reminderDate.isAtSameMomentAs(today);
        }).toList();

        // Use the first reminder time for today as the scheduled time
        // If no reminder time for today, use current time as fallback
        final scheduledTime = todaysReminderTimes.isNotEmpty
            ? todaysReminderTimes.first
            : now;

        // Create medication session with fixed schedule dosage
        final session = MedicationSession.create(
          petId: pet.id,
          userId: user.id,
          dateTime: DateTime.now(),
          medicationName: schedule.medicationName!,
          dosageGiven: schedule.targetDosage!, // Use schedule's target dosage
          dosageScheduled: schedule.targetDosage!,
          medicationUnit: schedule.medicationUnit!,
          medicationStrengthAmount: schedule.medicationStrengthAmount,
          medicationStrengthUnit: schedule.medicationStrengthUnit,
          customMedicationStrengthUnit: schedule.customMedicationStrengthUnit,
          completed: true, // Always true for manual logging
          notes: notes,
          scheduleId: schedule.id,
          scheduledTime: scheduledTime, // ✅ Now properly set!
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
              OverlayService.hide();

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
        // Success! Show indicator and close
        setState(() {
          _loadingState = LoadingOverlayState.success;
        });

        // Haptic feedback
        unawaited(HapticFeedback.lightImpact());

        // Wait for success animation, then close
        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // Reset state and close popup
          ref.read(loggingProvider.notifier).reset();
          OverlayService.hide();
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
    // Get today's scheduled time for this medication
    final now = DateTime.now();
    final todaysReminderTimes = medicationSchedule.reminderTimes.where((
      reminderTime,
    ) {
      final reminderDate = DateTime(
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      return reminderDate.isAtSameMomentAs(today);
    }).toList();

    // Use the first reminder time for today as the scheduled time
    // If no reminder time for today, use current time as fallback
    final scheduledTime = todaysReminderTimes.isNotEmpty
        ? todaysReminderTimes.first
        : now;

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

  /// Show error message using centralized error handler
  void _showError(String message) {
    if (!mounted) return;
    LoggingErrorHandler.showLoggingError(context, message);
    // Announce to screen readers
    SemanticsService.announce(message, TextDirection.ltr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schedules = ref.watch(todaysMedicationSchedulesProvider);

    return LoggingPopupWrapper(
      title: 'Log Medication',
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: LoadingOverlay(
        state: _loadingState,
        loadingMessage: 'Logging medication session',
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
                        ? 'Deselect All'
                        : 'Select All',
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
              'Select Medications:',
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
                  'No medications scheduled for today',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...schedules.map((schedule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: MedicationSelectionCard(
                    medication: schedule,
                    isSelected: _selectedMedicationIds.contains(
                      schedule.id,
                    ),
                    onTap: _loadingState != LoadingOverlayState.none
                        ? () {}
                        : () => _toggleMedication(schedule.id),
                  ),
                );
              }),

            // Notes field (appears right after medication selection)
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _notesController,
              focusNode: _notesFocusNode,
              maxLength: 500,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any notes about this treatment...',
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
              onChanged: (value) {
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

            // Log button
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              label: 'Log medication button',
              hint: _selectedMedicationIds.length == 1
                  ? 'Logs 1 selected medication and updates treatment '
                        'records'
                  : 'Logs ${_selectedMedicationIds.length} selected '
                        'medications and updates treatment records',
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
                      ? 'Log Medication'
                      : 'Log ${_selectedMedicationIds.length} Medications',
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
