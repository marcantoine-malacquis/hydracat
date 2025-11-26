import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/services/weight_calculator_service.dart';
import 'package:hydracat/features/logging/widgets/injection_site_selector.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/stress_level_selector.dart';
import 'package:hydracat/features/logging/widgets/weight_calculator_form.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/inputs/volume_input_adjuster.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Fluid therapy logging screen with volume input and optional fields.
///
/// Features:
/// - Editable volume input (pre-filled from schedule or default 100ml)
/// - Daily summary display (shows cumulative volume logged today)
/// - Injection site selector (pre-filled from schedule or default)
/// - Stress level selector (optional, low/medium/high)
/// - Notes field (optional, expandable, max 500 characters)
/// - Loading overlay during batch write
/// - Success animation with haptic feedback
/// - No duplicate detection (partial sessions are valid)
/// - Schedule validation from notification (via initialScheduleId)
class FluidLoggingScreen extends ConsumerStatefulWidget {
  /// Creates a [FluidLoggingScreen].
  ///
  /// If [initialScheduleId] is provided, the schedule will be validated
  /// against the current fluid schedule. This is used for notification
  /// deep-linking. Validation is silent - no user-facing error is shown
  /// if the schedule doesn't match.
  const FluidLoggingScreen({
    this.initialScheduleId,
    super.key,
  });

  /// Optional schedule ID for validation from notification deep-link.
  ///
  /// Since fluid has only a single schedule, this is used for validation
  /// rather than pre-selection. If the schedule ID doesn't match the
  /// current fluid schedule, a warning is logged but the screen opens
  /// normally.
  final String? initialScheduleId;

  @override
  ConsumerState<FluidLoggingScreen> createState() => _FluidLoggingScreenState();
}

/// View mode for fluid input
enum _FluidInputMode {
  /// Standard form with volume input
  standard,

  /// Weight calculator for volume calculation
  calculator,
}

class _FluidLoggingScreenState extends ConsumerState<FluidLoggingScreen> {
  // Form controllers
  final TextEditingController _notesController = TextEditingController();

  // Form state
  double _volumeValue = 100;

  // Selection state
  FluidLocation _selectedInjectionSite = FluidLocation.shoulderBladeLeft;
  String _selectedStressLevel = 'medium';

  // UI state
  LoadingOverlayState _loadingState = LoadingOverlayState.none;

  // Weight calculator state (pending result pattern)
  WeightCalculatorResult? _pendingWeightResult;

  // View mode state
  _FluidInputMode _inputMode = _FluidInputMode.standard;

  // Focus nodes
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Listen to focus changes for counter visibility
    _notesFocusNode.addListener(() {
      setState(() {}); // Rebuild to update counter visibility
    });

    // Pre-fill from schedule after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromSchedule();
    });

    // Validate schedule from notification (if provided)
    if (widget.initialScheduleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _validateNotificationSchedule(widget.initialScheduleId!);
      });
    }

    // Ensure schedule is loaded if not present yet (robustness on hot restart)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hasSchedule = ref.read(fluidScheduleProvider) != null;
      final isLoading = ref.read(scheduleIsLoadingProvider);
      final pet = ref.read(primaryPetProvider);
      if (pet != null && !hasSchedule && !isLoading) {
        ref.read(profileProvider.notifier).loadFluidSchedule();
      }
    });

    // Listen for schedule changes and update pre-filled values
    // This ensures the form reflects the latest schedule data even if
    // user updates the schedule in the profile screen
    ref.listenManual(
      fluidScheduleProvider,
      (previous, next) {
        if (kDebugMode) {
          debugPrint('[FluidLoggingScreen] Schedule provider changed:');
          debugPrint('  Previous volume: ${previous?.targetVolume}ml');
          debugPrint('  Next volume: ${next?.targetVolume}ml');
          debugPrint('  Previous location: ${previous?.preferredLocation}');
          debugPrint('  Next location: ${next?.preferredLocation}');
        }

        // Update if schedule data changed
        if (previous?.targetVolume != next?.targetVolume ||
            previous?.preferredLocation != next?.preferredLocation) {
          if (kDebugMode) {
            debugPrint('[FluidLoggingScreen] Schedule changed - updating form');
          }
          _prefillFromSchedule();
        }
      },
    );
  }

  /// Validate fluid schedule from notification deep-link.
  ///
  /// Checks if the schedule ID from the notification matches the current
  /// fluid schedule. Since fluid has only a single schedule, this is used
  /// for validation/logging rather than pre-selection.
  ///
  /// No user-facing error is shown - validation failure is only logged.
  void _validateNotificationSchedule(String scheduleId) {
    final schedule = ref.read(fluidScheduleProvider);

    if (schedule == null || schedule.id != scheduleId) {
      debugPrint(
        '[FluidLoggingScreen] ⚠️ Fluid schedule $scheduleId from '
        'notification not found or changed',
      );
      // No user-facing error - fluid screen works normally
    } else {
      debugPrint(
        '[FluidLoggingScreen] Fluid schedule from notification validated: '
        '$scheduleId',
      );
    }
  }

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Get the last used injection site from recent sessions
  Future<FluidLocation?> _getLastUsedInjectionSite() async {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) return null;

    try {
      final firestore = FirebaseFirestore.instance;

      // Query most recent session with injection site
      final query = await firestore
          .collection('users')
          .doc(user.id)
          .collection('pets')
          .doc(pet.id)
          .collection('fluidSessions')
          .orderBy('dateTime', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final session = FluidSession.fromJson(query.docs.first.data());
      return session.injectionSite;
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[FluidLoggingScreen] Error fetching last injection site: $e',
        );
      }
      return null;
    }
  }

  /// Pre-fill form from schedule (if available) or use smart defaults
  Future<void> _prefillFromSchedule() async {
    final fluidSchedule = ref.read(fluidScheduleProvider);

    if (fluidSchedule != null) {
      // Pre-fill from schedule - always use the latest data
      final newVolume = fluidSchedule.targetVolume ?? 100;

      setState(() {
        _volumeValue = newVolume;
        _selectedInjectionSite =
            fluidSchedule.preferredLocation ?? FluidLocation.shoulderBladeLeft;
      });

      if (kDebugMode) {
        debugPrint(
          '[FluidLoggingScreen] Pre-filled from schedule: '
          'volume=${fluidSchedule.targetVolume}ml, '
          'site=${_selectedInjectionSite.displayName}',
        );
      }
    } else {
      // Manual logging - try to use last used injection site
      // Fetch last used injection site for smart defaults
      final lastUsedSite = await _getLastUsedInjectionSite();

      setState(() {
        _volumeValue = 100;
        _selectedInjectionSite =
            lastUsedSite ?? FluidLocation.shoulderBladeLeft;
      });

      if (kDebugMode) {
        debugPrint(
          '[FluidLoggingScreen] Using smart defaults: '
          'volume=100ml, site=${_selectedInjectionSite.displayName} '
          '${lastUsedSite != null ? "(last used)" : "(default)"}',
        );
      }
    }
  }

  /// Check if form is valid
  bool get _isFormValid {
    return _volumeValue >= 1 && _volumeValue <= 500;
  }

  /// Log fluid session
  Future<void> _logFluidSession() async {
    if (!_isFormValid) return;
    // Avoid flicker: only show loading UI if operation takes longer than
    // a short threshold. This prevents a brief grey flash when writes are fast.
    final showLoadingTimer = Timer(const Duration(milliseconds: 120), () {
      if (mounted && _loadingState == LoadingOverlayState.none) {
        setState(() {
          _loadingState = LoadingOverlayState.loading;
        });
      }
    });

    var success = false;
    try {
      final user = ref.read(currentUserProvider);
      final pet = ref.read(primaryPetProvider);
      final fluidSchedule = ref.read(fluidScheduleProvider);
      final l10n = AppLocalizations.of(context)!;

      if (user == null || pet == null) {
        _showError(l10n.loggingUserNotFound);
        return;
      }

      final volume = _volumeValue;
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text;

      // Create fluid session
      final session = FluidSession.create(
        petId: pet.id,
        userId: user.id,
        dateTime: DateTime.now(),
        volumeGiven: volume,
        injectionSite: _selectedInjectionSite,
        stressLevel: _selectedStressLevel,
        notes: notes,
        scheduleId: fluidSchedule?.id,
        scheduledTime: fluidSchedule?.reminderTimes.firstOrNull,
        calculatedFromWeight: _pendingWeightResult != null,
        initialBagWeightG: _pendingWeightResult?.initialWeightG,
        finalBagWeightG: _pendingWeightResult?.finalWeightG,
      );

      // Log the session
      success = await ref
          .read(loggingProvider.notifier)
          .logFluidSession(
            session: session,
            fluidSchedule: fluidSchedule,
          );

      if (success) {
        // Persist last bag weight for next session
        // (if weight calculator was used)
        if (_pendingWeightResult != null) {
          final weightCalc = ref.read(weightCalculatorServiceProvider);
          await weightCalc.saveLastBagWeight(
            userId: user.id,
            petId: pet.id,
            finalWeightG: _pendingWeightResult!.finalWeightG,
          );

          // Clear pending result after persistence
          setState(() {
            _pendingWeightResult = null;
          });
        }

        // Ensure the delayed loading timer cannot flip state back to loading
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
          // Note: Reset happens after cache is updated to ensure
          // consistent state
          ref.read(loggingProvider.notifier).reset();
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } else {
        // Error occurred - check error provider
        final error = ref.read(loggingErrorProvider);
        if (error != null) {
          _showError(error);
        }
      }
    } finally {
      // Ensure we don't leak the timer
      showLoadingTimer.cancel();
      if (mounted && !success) {
        // Only reset state if there was an error
        // (success state is handled above)
        setState(() {
          _loadingState = LoadingOverlayState.none;
        });
      }
    }
  }

  /// Toggle to calculator view
  void _toggleToCalculator() {
    setState(() {
      _inputMode = _FluidInputMode.calculator;
    });
  }

  /// Handle calculator result and return to standard form
  void _handleCalculatorResult(WeightCalculatorResult result) {
    setState(() {
      _pendingWeightResult = result;
      _volumeValue = result.volumeMl;
      _inputMode = _FluidInputMode.standard;
    });
  }

  /// Handle calculator cancellation and return to standard form
  void _handleCalculatorCancel() {
    setState(() {
      _inputMode = _FluidInputMode.standard;
    });
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

  /// Build standard form view with volume input
  Widget _buildStandardForm(AppLocalizations l10n, ThemeData theme) {
    final cache = ref.watch(dailyCacheProvider);

    return Column(
      key: const ValueKey('standard'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily summary info card (if fluids already logged today)
        if (cache != null && cache.totalFluidVolumeGiven > 0) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.fluidAlreadyLoggedToday(
                    cache.totalFluidVolumeGiven.toInt(),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Volume input
        VolumeInputAdjuster(
          initialValue: _volumeValue,
          onChanged: (value) {
            setState(() {
              _volumeValue = value;
            });
          },
          minValue: 1,
        ),
        const SizedBox(height: AppSpacing.md),

        // Weight calculator button
        Center(
          child: HydraButton(
            variant: HydraButtonVariant.text,
            onPressed: _loadingState == LoadingOverlayState.none
                ? _toggleToCalculator
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calculate, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.calculateFromWeight),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Injection site selector
        InjectionSiteSelector(
          value: _selectedInjectionSite,
          onChanged: (FluidLocation newValue) {
            if (_loadingState == LoadingOverlayState.none) {
              setState(() {
                _selectedInjectionSite = newValue;
              });
            }
          },
          enabled: _loadingState == LoadingOverlayState.none,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Stress level selector
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fluidStressLevelLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            StressLevelSelector(
              value: _selectedStressLevel,
              onChanged: (String newValue) {
                if (_loadingState == LoadingOverlayState.none) {
                  setState(() {
                    _selectedStressLevel = newValue;
                  });
                }
              },
              enabled: _loadingState == LoadingOverlayState.none,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Notes field (matches medication screen behavior)
        HydraTextField(
          controller: _notesController,
          focusNode: _notesFocusNode,
          maxLength: 500,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.loggingNotesLabel,
            hintText: l10n.loggingNotesHintSession,
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
              child: Text(
                '${_notesController.text.length}/500',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          // Show as multiline when has content
          minLines: _notesController.text.isNotEmpty ? 3 : 1,
          maxLines: 5,
        ),

        // Log button
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: l10n.fluidLogButtonLabel,
          hint: l10n.fluidLogButtonHint,
          button: true,
          child: HydraButton(
            variant: HydraButtonVariant.primary,
            isFullWidth: true,
            isLoading: _loadingState == LoadingOverlayState.loading,
            onPressed: _isFormValid && _loadingState == LoadingOverlayState.none
                ? _logFluidSession
                : null,
            semanticLabel: l10n.fluidLogButtonLabel,
            child: Text(l10n.fluidLoggingTitle),
          ),
        ),
      ],
    );
  }

  /// Build calculator view with weight inputs
  Widget _buildCalculatorView() {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      return const SizedBox.shrink();
    }

    return Column(
      key: const ValueKey('calculator'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WeightCalculatorForm(
          userId: user.id,
          petId: pet.id,
          onVolumeCalculated: _handleCalculatorResult,
          onCancel: _handleCalculatorCancel,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Watch the schedule provider to ensure form stays in sync
    // This is a fallback in case the listener doesn't work properly
    // Read schedule to keep the widget reactive, but avoid overwriting
    // user's input within build. Prefill is handled in initState.
    ref.watch(fluidScheduleProvider);

    // Do NOT overwrite user's input during build; schedule prefill happens in
    // initState via _prefillFromSchedule and ref.listenManual above.
    // Overwriting here would cause the volume field to reset as the user types.

    return LoggingPopupWrapper(
      title: _inputMode == _FluidInputMode.standard
          ? l10n.fluidLoggingTitle
          : l10n.weightCalculatorTitle,
      leading: _inputMode == _FluidInputMode.calculator
          ? HydraBackButton(
              onPressed: _handleCalculatorCancel,
            )
          : null,
      onDismiss: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        ref.read(loggingProvider.notifier).reset();
      },
      child: LoadingOverlay(
        state: _loadingState,
        loadingMessage: l10n.fluidLoggingLoadingMessage,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated view switcher (standard form ↔ calculator)
            AnimatedSwitcher(
              duration: AppAnimations.getDuration(
                context,
                const Duration(milliseconds: 250),
              ),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.03, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _inputMode == _FluidInputMode.standard
                  ? _buildStandardForm(l10n, theme)
                  : _buildCalculatorView(),
            ),
          ],
        ),
      ),
    );
  }
}
