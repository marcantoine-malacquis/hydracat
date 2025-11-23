import 'package:flutter/material.dart';
import 'package:hydracat/features/logging/widgets/weight_calculator_form.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Dialog wrapper for calculating fluid volume from weight measurements
///
/// Wraps [WeightCalculatorForm] in an AlertDialog for backward compatibility
/// and dialog-based use cases.
///
/// For inline usage, use [WeightCalculatorForm] directly.
class WeightCalculatorDialog extends StatelessWidget {
  /// Creates a [WeightCalculatorDialog]
  const WeightCalculatorDialog({
    required this.userId,
    required this.petId,
    super.key,
  });

  /// Current user ID for scoped data access
  final String userId;

  /// Pet ID for scoped data access
  final String petId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return HydraAlertDialog(
      title: Text(l10n.weightCalculatorTitle),
      content: WeightCalculatorForm(
        userId: userId,
        petId: petId,
        onVolumeCalculated: (result) {
          Navigator.of(context).pop(result);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
