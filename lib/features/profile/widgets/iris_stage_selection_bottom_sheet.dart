import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/logging/widgets/logging_popup_wrapper.dart';
import 'package:hydracat/features/onboarding/widgets/iris_stage_selector.dart';
import 'package:hydracat/features/profile/models/medical_info.dart';

/// Bottom sheet for selecting IRIS stage
///
/// Allows users to select or change their pet's IRIS stage.
/// Returns the selected [IrisStage] when Save is pressed, or null if dismissed.
class IrisStageSelectionBottomSheet extends StatefulWidget {
  /// Creates an [IrisStageSelectionBottomSheet]
  const IrisStageSelectionBottomSheet({
    required this.initialStage,
    super.key,
  });

  /// The currently selected IRIS stage (null if not set)
  final IrisStage? initialStage;

  @override
  State<IrisStageSelectionBottomSheet> createState() =>
      _IrisStageSelectionBottomSheetState();
}

class _IrisStageSelectionBottomSheetState
    extends State<IrisStageSelectionBottomSheet> {
  late IrisStage? _selectedStage;

  @override
  void initState() {
    super.initState();
    _selectedStage = widget.initialStage;
  }

  Widget _buildHeaderAction() {
    final isCupertino =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return TextButton(
      onPressed: _save,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        'Save',
        style: AppTextStyles.buttonPrimary.copyWith(
          fontWeight: isCupertino ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }

  void _save() {
    // Return the selected stage (can be null)
    Navigator.of(context).pop(_selectedStage);
  }

  @override
  Widget build(BuildContext context) {
    return LoggingPopupWrapper(
      title: 'Select IRIS Stage',
      trailing: _buildHeaderAction(),
      showCloseButton: false,
      onDismiss: () {
        // No special cleanup needed
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),

          // IRIS Stage selector
          IrisStageSelector(
            selectedStage: _selectedStage,
            hasUserSelected: true,
            onStageChanged: (stage) {
              setState(() {
                _selectedStage = stage;
              });
            },
          ),
        ],
      ),
    );
  }
}
