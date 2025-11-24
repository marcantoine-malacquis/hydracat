import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/widgets/rotating_wheel_picker.dart';
import 'package:hydracat/features/profile/models/schedule.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';
import 'package:uuid/uuid.dart';

/// Screen for creating a new fluid schedule
///
/// This screen can be accessed from multiple entry points:
/// - Profile screen "Add fluid therapy" button
/// - Home screen empty state
/// - FAB "No schedules" dialog
class CreateFluidScheduleScreen extends ConsumerStatefulWidget {
  /// Creates a [CreateFluidScheduleScreen]
  const CreateFluidScheduleScreen({super.key});

  @override
  ConsumerState<CreateFluidScheduleScreen> createState() =>
      _CreateFluidScheduleScreenState();
}

class _CreateFluidScheduleScreenState
    extends ConsumerState<CreateFluidScheduleScreen> {
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
    _initializeDefaults();
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _needleGaugeController.dispose();
    super.dispose();
  }

  void _initializeDefaults() {
    // Set default values for new schedule
    _volumeController.text = '100';
    _volumePerAdministration = 100;
    _needleGaugeController.text = '20G';
    _needleGauge = '20G';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Fluid Therapy Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                _buildHeader(context, theme, l10n),

                const SizedBox(height: 32),

                // Content sections
                _buildFrequencySection(theme, l10n),
                const SizedBox(height: 32),
                _buildVolumeSection(theme, l10n),
                const SizedBox(height: 32),
                _buildLocationSection(theme, l10n),
                const SizedBox(height: 32),
                _buildNeedleGaugeSection(theme, l10n),
                const SizedBox(height: 32),

                // Footer with save button
                _buildFooter(context, theme, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
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
            Expanded(
              child: Text(
                'Fluid Therapy Setup',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
                  'You can update your fluid schedule anytime in the '
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
          'Volume per session (mL)',
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
            // The library directive may trigger
            // deprecated_member_use warnings
            // in some Dart versions.
            // ignore: deprecated_member_use
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
        const SizedBox(height: 8),
        if (_selectedFrequency.administrationsPerDay > 0 &&
            _volumePerAdministration > 0)
          Text(
            l10n.totalPlannedToday(
              (_selectedFrequency.administrationsPerDay *
                      _volumePerAdministration)
                  .toInt(),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onSave,
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
                'Save Fluid Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create Schedule object for fluid therapy
      const uuid = Uuid();
      final now = DateTime.now();
      final schedule = Schedule(
        id: uuid.v4(),
        treatmentType: TreatmentType.fluid,
        frequency: _selectedFrequency,
        targetVolume: _volumePerAdministration,
        preferredLocation: _preferredLocation,
        needleGauge: _needleGauge,
        reminderTimes: _getDefaultReminderTimes(_selectedFrequency),
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore via ProfileProvider
      await ref.read(profileProvider.notifier).createFluidSchedule(schedule);

      if (mounted && context.mounted) {
        // Show success message
        HydraSnackBar.showSuccess(
          context,
          'Fluid schedule saved successfully!',
        );

        // Navigate back
        context.pop();
      }
    } on Exception catch (e) {
      if (mounted) {
        HydraSnackBar.showError(context, 'Error saving fluid schedule: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Helper to generate default reminder times based on frequency
  List<DateTime> _getDefaultReminderTimes(TreatmentFrequency frequency) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return switch (frequency) {
      TreatmentFrequency.onceDaily => [
        today.add(const Duration(hours: 9)),
      ],
      TreatmentFrequency.twiceDaily => [
        today.add(const Duration(hours: 9)),
        today.add(const Duration(hours: 21)),
      ],
      TreatmentFrequency.thriceDaily => [
        today.add(const Duration(hours: 8)),
        today.add(const Duration(hours: 14)),
        today.add(const Duration(hours: 20)),
      ],
      TreatmentFrequency.everyOtherDay => [
        today.add(const Duration(hours: 9)),
      ],
      TreatmentFrequency.every3Days => [
        today.add(const Duration(hours: 9)),
      ],
    };
  }
}
