import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/features/onboarding/models/onboarding_data.dart';
import 'package:hydracat/features/onboarding/screens/treatment_fluid_screen.dart';
import 'package:hydracat/features/onboarding/screens/treatment_medication_screen.dart';
import 'package:hydracat/features/profile/models/user_persona.dart';
import 'package:hydracat/providers/onboarding_provider.dart';

/// Router screen that determines treatment setup flow based on persona
class TreatmentSetupScreen extends ConsumerStatefulWidget {
  /// Creates a [TreatmentSetupScreen]
  const TreatmentSetupScreen({super.key});

  @override
  ConsumerState<TreatmentSetupScreen> createState() => 
      _TreatmentSetupScreenState();
}

class _TreatmentSetupScreenState extends ConsumerState<TreatmentSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingDataProvider);
    final persona = onboardingData?.treatmentApproach;

    // If no persona selected, shouldn't happen but handle gracefully
    if (persona == null) {
      return _buildErrorScreen(
        'No treatment approach selected',
        'Please go back and select your treatment approach.',
      );
    }

    // Route to appropriate treatment setup flow based on persona
    return switch (persona) {
      UserPersona.medicationOnly => const TreatmentMedicationScreen(),
      UserPersona.fluidTherapyOnly => const TreatmentFluidScreen(),
      UserPersona.medicationAndFluidTherapy => _CombinedTreatmentFlow(
          onboardingData: onboardingData,
        ),
    };
  }

  Widget _buildErrorScreen(String title, String message) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Treatment Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget that handles the combined medication and fluid therapy flow
class _CombinedTreatmentFlow extends ConsumerStatefulWidget {
  /// Creates a [_CombinedTreatmentFlow]
  const _CombinedTreatmentFlow({
    required this.onboardingData,
  });

  /// Current onboarding data
  final OnboardingData? onboardingData;

  @override
  ConsumerState<_CombinedTreatmentFlow> createState() => 
      _CombinedTreatmentFlowState();
}

class _CombinedTreatmentFlowState 
    extends ConsumerState<_CombinedTreatmentFlow> {
  @override
  Widget build(BuildContext context) {
    final onboardingData = ref.watch(onboardingDataProvider);
    final hasMedications = onboardingData?.medications?.isNotEmpty ?? false;
    final hasFluidTherapy = onboardingData?.fluidTherapy != null;

    // Determine which screen to show based on current progress
    if (!hasMedications) {
      // First: show medication setup
      return const TreatmentMedicationScreen();
    } else if (!hasFluidTherapy) {
      // Second: show fluid therapy setup  
      return const TreatmentFluidScreen();
    } else {
      // Both complete, go to completion
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/onboarding/completion');
      });
      return _buildLoadingScreen();
    }
  }

  Widget _buildLoadingScreen() {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Helper widget for treatment setup navigation
class TreatmentSetupNavigator extends ConsumerWidget {
  /// Creates a [TreatmentSetupNavigator]
  const TreatmentSetupNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingData = ref.watch(onboardingDataProvider);
    final persona = onboardingData?.treatmentApproach;

    if (persona == null) {
      return const SizedBox.shrink();
    }

    return _buildNavigationInfo(context, persona, onboardingData);
  }

  Widget _buildNavigationInfo(
    BuildContext context, 
    UserPersona persona, 
    OnboardingData? onboardingData,
  ) {
    final theme = Theme.of(context);
    final progress = _calculateProgress(persona, onboardingData);
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.route,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Treatment Setup Progress',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          
          Text(
            _getProgressText(persona, onboardingData),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateProgress(
    UserPersona persona, 
    OnboardingData? onboardingData,
  ) {
    return switch (persona) {
      UserPersona.medicationOnly => 
        (onboardingData?.medications?.isNotEmpty ?? false) ? 1.0 : 0.0,
      UserPersona.fluidTherapyOnly => 
        (onboardingData?.fluidTherapy != null) ? 1.0 : 0.0,
      UserPersona.medicationAndFluidTherapy => () {
        final hasMeds = onboardingData?.medications?.isNotEmpty ?? false;
        final hasFluid = onboardingData?.fluidTherapy != null;
        if (hasMeds && hasFluid) return 1.0;
        if (hasMeds || hasFluid) return 0.5;
        return 0.0;
      }(),
    };
  }

  String _getProgressText(
    UserPersona persona, 
    OnboardingData? onboardingData,
  ) {
    return switch (persona) {
      UserPersona.medicationOnly => 
        (onboardingData?.medications?.isNotEmpty ?? false) 
          ? 'Medication setup complete!'
          : 'Set up your medications',
      UserPersona.fluidTherapyOnly => 
        (onboardingData?.fluidTherapy != null) 
          ? 'Fluid therapy setup complete!'
          : 'Set up your fluid therapy',
      UserPersona.medicationAndFluidTherapy => () {
        final hasMeds = onboardingData?.medications?.isNotEmpty ?? false;
        final hasFluid = onboardingData?.fluidTherapy != null;
        if (hasMeds && hasFluid) return 'Both setups complete!';
        if (hasMeds) {
          return 'Medications done. Set up fluid therapy next.';
        }
        if (hasFluid) {
          return 'Fluid therapy done. Set up medications next.';
        }
        return 'Set up medications, then fluid therapy';
      }(),
    };
  }
}
