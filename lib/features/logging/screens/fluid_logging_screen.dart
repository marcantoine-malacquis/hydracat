import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_animations.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/exceptions/logging_error_handler.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/injection_site_selector.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/stress_level_selector.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/loading/loading_overlay.dart';

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
class FluidLoggingScreen extends ConsumerStatefulWidget {
  /// Creates a [FluidLoggingScreen].
  const FluidLoggingScreen({super.key});

  @override
  ConsumerState<FluidLoggingScreen> createState() => _FluidLoggingScreenState();
}

class _FluidLoggingScreenState extends ConsumerState<FluidLoggingScreen> {
  // Form controllers
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selection state
  FluidLocation? _selectedInjectionSite;
  String? _selectedStressLevel;

  // UI state
  LoadingOverlayState _loadingState = LoadingOverlayState.none;
  String? _volumeError;

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

  @override
  void dispose() {
    _notesFocusNode.dispose();
    _volumeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Pre-fill form from schedule (if available) or use defaults
  void _prefillFromSchedule() {
    final fluidSchedule = ref.read(fluidScheduleProvider);

    if (fluidSchedule != null) {
      // Pre-fill from schedule - always use the latest data
      final newVolume = fluidSchedule.targetVolume?.toInt().toString() ?? '100';

      // Only update if the value has actually changed to
      // avoid unnecessary rebuilds
      if (_volumeController.text != newVolume) {
        _volumeController.text = newVolume;
      }

      setState(() {
        _selectedInjectionSite = fluidSchedule.preferredLocation;
      });

      if (kDebugMode) {
        debugPrint(
          '[FluidLoggingScreen] Pre-filled from schedule: '
          'volume=${fluidSchedule.targetVolume}ml',
        );
      }
    } else {
      // Manual logging - use defaults
      if (_volumeController.text != '100') {
        _volumeController.text = '100';
      }

      setState(() {
        _selectedInjectionSite = FluidLocation.shoulderBladeLeft;
      });

      if (kDebugMode) {
        debugPrint('[FluidLoggingScreen] Using default values (no schedule)');
      }
    }

    // Initial validation
    _validateVolume();
  }

  /// Validate volume input
  void _validateVolume() {
    final text = _volumeController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      if (text.isEmpty) {
        _volumeError = l10n.fluidVolumeRequired;
        return;
      }

      final volume = double.tryParse(text);

      if (volume == null) {
        _volumeError = l10n.fluidVolumeInvalid;
        return;
      }

      if (volume < 1) {
        _volumeError = l10n.fluidVolumeMin;
        return;
      }

      if (volume > 500) {
        _volumeError = l10n.fluidVolumeMax;
        return;
      }

      _volumeError = null;
    });
  }

  /// Check if form is valid
  bool get _isFormValid {
    return _volumeError == null && _volumeController.text.trim().isNotEmpty;
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

      final volume = double.parse(_volumeController.text.trim());
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
      );

      // Log the session
      success = await ref
          .read(loggingProvider.notifier)
          .logFluidSession(
            session: session,
          );

      if (success) {
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
          ref.read(loggingProvider.notifier).reset();
          OverlayService.hide();
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
    final l10n = AppLocalizations.of(context)!;
    final cache = ref.watch(dailyCacheProvider);

    // Watch the schedule provider to ensure form stays in sync
    // This is a fallback in case the listener doesn't work properly
    final currentSchedule = ref.watch(fluidScheduleProvider);

    // Update form if schedule data changed (reactive approach)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentSchedule != null) {
        final expectedVolume =
            currentSchedule.targetVolume?.toInt().toString() ?? '100';
        if (_volumeController.text != expectedVolume) {
          _volumeController.text = expectedVolume;
          _validateVolume();
        }

        if (_selectedInjectionSite != currentSchedule.preferredLocation) {
          setState(() {
            _selectedInjectionSite = currentSchedule.preferredLocation;
          });
        }
      }
    });

    return LoggingPopupWrapper(
      title: l10n.fluidLoggingTitle,
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: LoadingOverlay(
        state: _loadingState,
        loadingMessage: l10n.fluidLoggingLoadingMessage,
        child: Column(
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
            TextField(
              controller: _volumeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.volumeLabel,
                hintText: l10n.volumeHint,
                errorText: _volumeError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
              onChanged: (value) {
                _validateVolume();
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Injection site selector
            InjectionSiteSelector(
              value: _selectedInjectionSite,
              onChanged: (FluidLocation? newValue) {
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
                  onChanged: (String? newValue) {
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
            TextField(
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
                  child: Text('${_notesController.text.length}/500'),
                ),
              ),
              // Expand to 3 lines when has content
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
              label: l10n.fluidLogButtonLabel,
              hint: l10n.fluidLogButtonHint,
              button: true,
              child: FilledButton(
                onPressed:
                    _isFormValid && _loadingState == LoadingOverlayState.none
                    ? _logFluidSession
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
                  l10n.fluidLoggingTitle,
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
