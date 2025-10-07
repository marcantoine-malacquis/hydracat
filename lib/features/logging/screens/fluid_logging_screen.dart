import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/logging/models/fluid_session.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/features/logging/widgets/injection_site_selector.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/logging/widgets/stress_level_selector.dart';
import 'package:hydracat/features/logging/widgets/success_indicator.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';

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
  ConsumerState<FluidLoggingScreen> createState() =>
      _FluidLoggingScreenState();
}

class _FluidLoggingScreenState extends ConsumerState<FluidLoggingScreen> {
  // Form controllers
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Selection state
  FluidLocation? _selectedInjectionSite;
  String? _selectedStressLevel;

  // UI state
  bool _isLoading = false;
  bool _showSuccess = false;
  String? _volumeError;
  bool _isNotesFocused = false;

  // Focus nodes
  final FocusNode _notesFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Listen to focus changes
    _notesFocusNode.addListener(() {
      setState(() {
        _isNotesFocused = _notesFocusNode.hasFocus;
      });
    });

    // Pre-fill from schedule after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromSchedule();
    });
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
    final fluidSchedule = ref.read(todaysFluidScheduleProvider);

    if (fluidSchedule != null) {
      // Pre-fill from schedule
      _volumeController.text =
          fluidSchedule.targetVolume?.toInt().toString() ?? '100';

      setState(() {
        _selectedInjectionSite = fluidSchedule.preferredLocation;
      });
    } else {
      // Manual logging - use defaults
      _volumeController.text = '100';

      setState(() {
        _selectedInjectionSite = FluidLocation.shoulderBladeLeft;
      });
    }

    // Initial validation
    _validateVolume();
  }

  /// Validate volume input
  void _validateVolume() {
    final text = _volumeController.text.trim();

    setState(() {
      if (text.isEmpty) {
        _volumeError = 'Volume is required';
        return;
      }

      final volume = double.tryParse(text);

      if (volume == null) {
        _volumeError = 'Please enter a valid number';
        return;
      }

      if (volume < 1) {
        _volumeError = 'Volume must be at least 1ml';
        return;
      }

      if (volume > 500) {
        _volumeError = 'Volume must be 500ml or less';
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

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider);
      final pet = ref.read(primaryPetProvider);
      final fluidSchedule = ref.read(todaysFluidScheduleProvider);

      if (user == null || pet == null) {
        _showError('User or pet not found. Please try again.');
        return;
      }

      final volume = double.parse(_volumeController.text.trim());
      final notes =
          _notesController.text.trim().isEmpty ? null : _notesController.text;

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
      final success =
          await ref.read(loggingProvider.notifier).logFluidSession(
                session: session,
              );

      if (success) {
        // Success! Show indicator and close
        setState(() {
          _showSuccess = true;
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = false;
        });
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cache = ref.watch(dailyCacheProvider);

    // Loading/success overlay
    final overlay = _isLoading || _showSuccess
        ? ColoredBox(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: _showSuccess
                  ? const SuccessIndicator()
                  : const CircularProgressIndicator(),
            ),
          )
        : null;

    return LoggingPopupWrapper(
      title: 'Log Fluid Session',
      onDismiss: () {
        ref.read(loggingProvider.notifier).reset();
      },
      child: Stack(
        children: [
          // Main content
          Opacity(
            opacity: _isLoading || _showSuccess ? 0.3 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Daily summary info card (if fluids already logged today)
                if (cache != null && cache.totalFluidVolumeGiven > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${cache.totalFluidVolumeGiven.toInt()}mL already '
                          'logged today',
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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Volume (ml)',
                    hintText: 'Enter volume in milliliters',
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
                    if (!_isLoading) {
                      setState(() {
                        _selectedInjectionSite = newValue;
                      });
                    }
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Stress level selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stress Level (optional):',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StressLevelSelector(
                      value: _selectedStressLevel,
                      onChanged: (String? newValue) {
                        if (!_isLoading) {
                          setState(() {
                            _selectedStressLevel = newValue;
                          });
                        }
                      },
                      enabled: !_isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Notes field (matches medication screen behavior)
                TextField(
                  controller: _notesController,
                  focusNode: _notesFocusNode,
                  maxLength: _isNotesFocused ? 500 : null,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any notes about this session...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    counterText: _isNotesFocused ? null : '',
                  ),
                  // Expand to 3 lines when has content
                  onTap: () {
                    setState(() {
                      // TextField will expand when tapped
                    });
                  },
                  onChanged: (value) {
                    // Rebuild to show expanded field
                    if (value.isNotEmpty && _notesController.text.length == 1) {
                      setState(() {});
                    }
                  },
                  // Show as multiline when has content
                  minLines: _notesController.text.isNotEmpty ? 3 : 1,
                  maxLines: 5,
                ),

                // Log button
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed:
                      _isFormValid && !_isLoading ? _logFluidSession : null,
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
                  child: const Text(
                    'Log Fluid Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loading/Success overlay
          if (overlay != null) Positioned.fill(child: overlay),
        ],
      ),
    );
  }
}
