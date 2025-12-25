import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_accessibility.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/app_border_radius.dart';
import 'package:hydracat/core/theme/app_shadows.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/features/onboarding/models/medication_database_entry.dart';
import 'package:hydracat/features/onboarding/models/medication_search_result.dart';
import 'package:hydracat/providers/medication_database_provider.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_text_form_field.dart';

/// Autocomplete text field for medication entry with intent-based display
///
/// Provides real-time search suggestions from the CKD medication database
/// as the user types. Displays results based on detected search intent:
/// - Brand search: Shows "Cerenia (Maropitant) 16mg tablet"
/// - Generic search: Shows "Maropitant 16mg tablet"
///
/// Features:
/// - Intent-based display (respects what user searched for)
/// - Case-insensitive matching on medication name, brands, and aliases
/// - Relevance-sorted results (exact > starts with > contains)
/// - Limited to 10 results for dropdown performance
/// - Auto-fills medication details on selection
/// - Fields remain editable after selection
class MedicationAutocompleteField extends ConsumerStatefulWidget {
  /// Creates a medication autocomplete field
  const MedicationAutocompleteField({
    required this.controller,
    this.onMedicationSelected,
    this.onChanged,
    this.decoration,
    this.focusNode,
    super.key,
  });

  /// Controller for the text field
  final TextEditingController controller;

  /// Callback when a medication is selected from the dropdown
  final ValueChanged<MedicationDatabaseEntry>? onMedicationSelected;

  /// Callback when the text changes (manual typing)
  final ValueChanged<String>? onChanged;

  /// Custom decoration for the text field
  final InputDecoration? decoration;

  /// Optional focus node
  final FocusNode? focusNode;

  @override
  ConsumerState<MedicationAutocompleteField> createState() =>
      _MedicationAutocompleteFieldState();
}

class _MedicationAutocompleteFieldState
    extends ConsumerState<MedicationAutocompleteField> {
  /// Current search query
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Watch search results for the current query
    final searchResults = ref.watch(medicationSearchProvider(_query));

    return RawAutocomplete<MedicationSearchResult>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode ?? FocusNode(),
      optionsBuilder: (TextEditingValue textEditingValue) {
        // Update query state when text changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _query != textEditingValue.text) {
            setState(() {
              _query = textEditingValue.text;
            });
          }
        });
        return searchResults;
      },
      displayStringForOption: _getNameToFill,
      onSelected: (MedicationSearchResult result) {
        // Pass the medication entry (not the search result) to callback
        widget.onMedicationSelected?.call(result.medication);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return HydraTextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: widget.decoration ??
              InputDecoration(
                hintText: l10n.medicationAutocompleteHint,
              ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            setState(() {
              _query = value;
            });
            widget.onChanged?.call(value);
          },
        );
      },
      optionsViewBuilder: _buildOptionsOverlay,
    );
  }

  /// Determines what name to fill in the text field based on search intent
  ///
  /// Intent-based filling logic:
  /// - Brand intent: Fill matched brand or primary brand
  /// - Generic intent: Fill generic name
  /// - Ambiguous: Fill primary brand if available, else generic
  String _getNameToFill(MedicationSearchResult result) {
    switch (result.intent) {
      case SearchIntent.brand:
        return result.matchedBrand ??
            result.medication.primaryBrandName ??
            result.medication.name;
      case SearchIntent.generic:
        return result.medication.name;
      case SearchIntent.ambiguous:
        return result.medication.primaryBrandName ?? result.medication.name;
    }
  }

  /// Builds the dropdown overlay for autocomplete options
  Widget _buildOptionsOverlay(
    BuildContext context,
    AutocompleteOnSelected<MedicationSearchResult> onSelected,
    Iterable<MedicationSearchResult> options,
  ) {
    // Hide dropdown if no options
    if (options.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        borderRadius: BorderRadius.circular(AppBorderRadius.input),
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 200, // Max ~4.5 items visible
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppBorderRadius.input),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: const [AppShadows.cardPopup],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: options.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.border,
            ),
            itemBuilder: (BuildContext context, int index) {
              final option = options.elementAt(index);
              return _buildOptionTile(context, option, onSelected);
            },
          ),
        ),
      ),
    );
  }

  /// Builds a single option tile in the dropdown with intent-based display
  Widget _buildOptionTile(
    BuildContext context,
    MedicationSearchResult result,
    AutocompleteOnSelected<MedicationSearchResult> onSelected,
  ) {
    return InkWell(
      onTap: () {
        onSelected(result);
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: AppAccessibility.minTouchTarget, // 44px minimum
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            // Intent-based display format
            result.displayName,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
