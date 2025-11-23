import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/features/logging/services/weight_calculator_service.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/providers/logging_provider.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Reusable form for calculating fluid volume from weight measurements
///
/// Can be used inline or within dialogs/screens.
///
/// Features:
/// - "Continue from same bag" banner (if applicable, <14 days)
/// - Initial and final weight inputs with inline validation
/// - Live volume calculation as user types
/// - Educational tips section
/// - Haptic feedback on success
/// - Focus management (keyboard auto-dismiss on weight auto-fill)
class WeightCalculatorForm extends ConsumerStatefulWidget {
  /// Creates a [WeightCalculatorForm]
  const WeightCalculatorForm({
    required this.userId,
    required this.petId,
    required this.onVolumeCalculated,
    required this.onCancel,
    super.key,
  });

  /// Current user ID for scoped data access
  final String userId;

  /// Pet ID for scoped data access
  final String petId;

  /// Callback when user confirms volume calculation
  final void Function(WeightCalculatorResult result) onVolumeCalculated;

  /// Callback when user cancels
  final VoidCallback onCancel;

  @override
  ConsumerState<WeightCalculatorForm> createState() =>
      _WeightCalculatorFormState();
}

class _WeightCalculatorFormState extends ConsumerState<WeightCalculatorForm> {
  late final TextEditingController _initialWeightController;
  late final TextEditingController _finalWeightController;
  late final FocusNode _initialFocusNode;
  late final FocusNode _finalFocusNode;

  double? _calculatedVolume;
  String? _errorMessage;
  LastBagWeight? _lastBagWeight;

  @override
  void initState() {
    super.initState();

    _initialWeightController = TextEditingController();
    _finalWeightController = TextEditingController();
    _initialFocusNode = FocusNode();
    _finalFocusNode = FocusNode();

    // Load last bag weight from service
    final service = ref.read(weightCalculatorServiceProvider);
    _lastBagWeight = service.getLastBagWeight(
      userId: widget.userId,
      petId: widget.petId,
    );

    // Add listeners for live calculation
    _initialWeightController.addListener(_calculateVolume);
    _finalWeightController.addListener(_calculateVolume);
  }

  @override
  void dispose() {
    _initialWeightController.dispose();
    _finalWeightController.dispose();
    _initialFocusNode.dispose();
    _finalFocusNode.dispose();
    super.dispose();
  }

  /// Parse weight input to double (handles null/empty/invalid)
  double? _parseWeight(String text) {
    final trimmed = text.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  /// Calculate volume and update state (live as user types)
  void _calculateVolume() {
    final initialG = _parseWeight(_initialWeightController.text);
    final finalG = _parseWeight(_finalWeightController.text);

    // Clear error when user starts typing
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Only calculate if both weights are provided
    if (initialG == null || finalG == null) {
      setState(() {
        _calculatedVolume = null;
      });
      return;
    }

    // Calculate volume
    final service = ref.read(weightCalculatorServiceProvider);
    final volumeMl = service.calculateVolumeMl(initialG, finalG);

    setState(() {
      _calculatedVolume = volumeMl;
    });
  }

  /// Use last bag weight to pre-fill initial weight field
  void _useLastBagWeight() {
    if (_lastBagWeight == null) return;

    // Unfocus to dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _initialWeightController.text =
          _lastBagWeight!.finalWeightG.toStringAsFixed(1);
      _errorMessage = null;
    });

    // Trigger recalculation
    _calculateVolume();
  }

  /// Validate and trigger callback with result
  void _useThisVolume() {
    final initialG = _parseWeight(_initialWeightController.text);
    final finalG = _parseWeight(_finalWeightController.text);

    final service = ref.read(weightCalculatorServiceProvider);
    final validation = service.validate(
      initialG: initialG,
      finalG: finalG,
    );

    if (!validation.isValid) {
      setState(() {
        _errorMessage = validation.errorMessage;
      });
      return;
    }

    // Validation passed - trigger haptic feedback
    HapticFeedback.mediumImpact();

    // Create result and trigger callback
    final result = WeightCalculatorResult(
      volumeMl: service.calculateVolumeMl(initialG!, finalG!),
      initialWeightG: initialG,
      finalWeightG: finalG,
    );

    widget.onVolumeCalculated(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Determine if "Use This Volume" button should be enabled
    final isValid = _calculatedVolume != null &&
        _calculatedVolume! >= 1 &&
        _calculatedVolume! <= 500;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "Continue from same bag?" banner (conditional)
          if (_lastBagWeight != null) ...[
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.continueFromSameBag,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.remainingWeight(
                      _lastBagWeight!.finalWeightG.toStringAsFixed(0),
                    ),
                    style: AppTextStyles.body.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    l10n.lastUsedDate(
                      AppDateUtils.formatDate(
                        _lastBagWeight!.lastUsedDate,
                        pattern: 'MMM d',
                      ),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _useLastBagWeight,
                      child: Text(l10n.useThisWeight),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Initial weight input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.beforeFluidTherapy,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              HydraTextField(
                controller: _initialWeightController,
                focusNode: _initialFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                autofocus: _lastBagWeight == null,
                decoration: InputDecoration(
                  labelText: l10n.initialWeightLabel,
                  suffixText: 'g',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,1}'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Final weight input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.afterFluidTherapy,
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              HydraTextField(
                controller: _finalWeightController,
                focusNode: _finalFocusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.finalWeightLabel,
                  suffixText: 'g',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,1}'),
                  ),
                ],
                onSubmitted: (_) {
                  if (isValid) {
                    _useThisVolume();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Live calculation display
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Text(
                  _calculatedVolume != null
                      ? l10n.fluidAdministered(
                          _calculatedVolume!.toStringAsFixed(0),
                        )
                      : l10n.fluidAdministered('--'),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.ringersDensityNote,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Error message (conditional)
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTextStyles.caption.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Important tips section
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.importantTipsTitle,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '• ${l10n.weightTip1}',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
                Text(
                  '• ${l10n.weightTip2}',
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: isValid ? _useThisVolume : null,
                child: Text(l10n.useThisVolume),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
