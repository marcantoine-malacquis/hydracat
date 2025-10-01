import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/features/onboarding/models/onboarding_step.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/onboarding_screen_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// Screen for setting up fluid therapy treatment
class TreatmentFluidScreen extends ConsumerStatefulWidget {
  /// Creates a [TreatmentFluidScreen]
  const TreatmentFluidScreen({
    super.key,
    this.onBack,
  });

  /// Optional callback for back navigation
  final VoidCallback? onBack;

  @override
  ConsumerState<TreatmentFluidScreen> createState() =>
      _TreatmentFluidScreenState();
}

class _TreatmentFluidScreenState extends ConsumerState<TreatmentFluidScreen> {
  final TextEditingController _volumeController = TextEditingController();
  final TextEditingController _needleGaugeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Form data
  TreatmentFrequency _selectedFrequency = TreatmentFrequency.onceDaily;
  double _volumePerAdministration = 0;
  FluidLocation _preferredLocation = FluidLocation.shoulderBladeLeft;
  String _needleGauge = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFromExisting();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _needleGaugeController.dispose();
    super.dispose();
  }

  void _initializeFromExisting() {
    final onboardingData = ref.read(onboardingDataProvider);
    if (onboardingData?.fluidTherapy != null) {
      final fluidTherapy = onboardingData!.fluidTherapy!;
      _selectedFrequency = fluidTherapy.frequency;
      _volumePerAdministration = fluidTherapy.volumePerAdministration;
      _volumeController.text = _volumePerAdministration.toString();
      _preferredLocation = fluidTherapy.preferredLocation;
      _needleGauge = fluidTherapy.needleGauge;
      _needleGaugeController.text = _needleGauge;
    } else {
      // Set default values
      _volumeController.text = '100';
      _volumePerAdministration = 100;
      _needleGaugeController.text = '20G';
      _needleGauge = '20G';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return OnboardingScreenWrapper(
      currentStep: 5,
      totalSteps: 6,
      title: l10n.fluidTherapySetupTitle,
      stepType: OnboardingStepType.treatmentSetup,
      onBackPressed: _onBackPressed,
      showNextButton: false,
      showProgressInAppBar: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeader(context, theme, l10n),

            // Content sections
            _buildFrequencySection(theme, l10n),
            const SizedBox(height: 32),
            _buildVolumeSection(theme, l10n),
            const SizedBox(height: 32),
            _buildLocationSection(theme, l10n),
            const SizedBox(height: 32),
            _buildNeedleGaugeSection(theme, l10n),
            const SizedBox(height: 32),

            // Footer with next button
            _buildFooter(context, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.water_drop,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Fluid Therapy Setup',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Configure your fluid therapy administration settings. '
            'This helps us provide appropriate tracking and reminders.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can update your schedules anytime in the '
                    'Profile section',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencySection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Administration Frequency',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'How often will fluid therapy be administered?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RotatingWheelPicker<TreatmentFrequency>(
            items: TreatmentFrequency.values,
            initialIndex: TreatmentFrequency.values.indexOf(
              _selectedFrequency,
            ),
            onSelectedItemChanged: (index) {
              setState(() {
                _selectedFrequency = TreatmentFrequency.values[index];
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Volume per Administration',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Enter the amount of fluid to be administered (in ml).',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _volumeController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$')),
          ],
          onChanged: (value) {
            setState(() {
              _volumePerAdministration = double.tryParse(value) ?? 0;
            });
          },
          decoration: InputDecoration(
            labelText: l10n.volumeLabel,
            hintText: l10n.volumeHint,
            suffixText: l10n.milliliters,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.local_drink),
            helperText: l10n.volumeHelperText,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Volume is required';
            }
            final volume = double.tryParse(value.trim());
            if (volume == null || volume <= 0) {
              return 'Please enter a valid volume';
            }
            if (volume > 500) {
              return 'Volume seems too high for a cat (max 500ml)';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferred Administration Location',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Where do you typically administer the fluids?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: RotatingWheelPicker<FluidLocation>(
            items: FluidLocation.values,
            initialIndex: FluidLocation.values.indexOf(_preferredLocation),
            onSelectedItemChanged: (index) {
              setState(() {
                _preferredLocation = FluidLocation.values[index];
              });
            },
          ),
        ),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Alternating injection sites helps prevent soreness and '
                  'maintains skin health.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedleGaugeSection(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Needle Gauge',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'What needle gauge do you typically use?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _needleGaugeController,
          onChanged: (value) {
            setState(() {
              _needleGauge = value.trim();
            });
          },
          decoration: InputDecoration(
            labelText: l10n.needleGaugeLabel,
            hintText: l10n.needleGaugeHint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.colorize),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Needle gauge is required';
            }
            return null;
          },
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            '18G',
            '20G',
            '22G',
            '25G',
          ].map((gauge) => _buildGaugeChip(gauge, theme)).toList(),
        ),
      ],
    );
  }

  Widget _buildGaugeChip(String gauge, ThemeData theme) {
    final isSelected = _needleGauge == gauge;

    return GestureDetector(
      onTap: () {
        setState(() {
          _needleGauge = gauge;
          _needleGaugeController.text = gauge;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          gauge,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onNext,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _onBackPressed() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final fluidTherapy = FluidTherapyData(
        frequency: _selectedFrequency,
        volumePerAdministration: _volumePerAdministration,
        preferredLocation: _preferredLocation,
        needleGauge: _needleGauge,
      );

      // Update onboarding data
      final currentData = ref.read(onboardingDataProvider);
      if (currentData != null) {
        await ref
            .read(onboardingProvider.notifier)
            .updateData(
              currentData.copyWith(fluidTherapy: fluidTherapy),
            );
      }

      // Move to next step
      final nextRoute = await ref
          .read(onboardingProvider.notifier)
          .navigateNext();

      if (nextRoute != null && mounted && context.mounted) {
        // Navigate to next screen
        context.go(nextRoute);
      }
    } on Exception catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        final errorMessage =
            ref.read(onboardingProvider.notifier).getErrorMessage(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
