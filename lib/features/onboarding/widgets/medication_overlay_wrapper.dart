import 'package:flutter/material.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';
import 'package:hydracat/features/onboarding/screens/add_medication_screen.dart';
import 'package:hydracat/shared/widgets/dialogs/unsaved_changes_dialog.dart';

/// A wrapper widget that integrates the medication popup with OverlayService
/// and handles unsaved changes detection.
class MedicationOverlayWrapper extends StatefulWidget {
  /// Creates a [MedicationOverlayWrapper]
  const MedicationOverlayWrapper({
    required this.initialMedication,
    required this.isEditing,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  /// Initial medication data for editing
  final MedicationData? initialMedication;

  /// Whether this is editing an existing medication
  final bool isEditing;

  /// Callback when medication is saved
  final void Function(MedicationData) onSave;

  /// Callback when medication editing is cancelled
  final VoidCallback onCancel;

  @override
  State<MedicationOverlayWrapper> createState() =>
      _MedicationOverlayWrapperState();
}

class _MedicationOverlayWrapperState extends State<MedicationOverlayWrapper> {
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    // If we have initial medication data, we start with unsaved changes
    // since any modification would be a change from the original
    _hasUnsavedChanges = widget.initialMedication != null;
  }

  /// Handle close button press with unsaved changes check
  void _handleClose() {
    if (!_hasUnsavedChanges) {
      widget.onCancel();
      return;
    }

    UnsavedChangesDialog.show(
      context: context,
      onSave: () {
        // For now, we don't have a way to save from the dialog
        // The user would need to complete the form and use the Save button
        widget.onCancel();
      },
      onDiscard: () {
        widget.onCancel();
      },
    );
  }

  /// Handle save action
  void _handleSave(MedicationData medication) {
    widget.onSave(medication);
  }

  /// Handle when user makes changes to the form
  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.9,
          maxWidth: 400,
        ),
        margin: const EdgeInsets.all(16),
        child: AddMedicationScreen(
          initialMedication: widget.initialMedication,
          isEditing: widget.isEditing,
          onSave: _handleSave,
          onCancel: _handleClose,
          onFormChanged: _onFormChanged,
        ),
      ),
    );
  }
}
