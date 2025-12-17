import 'package:flutter/material.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/qol/models/qol_domain.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:hydracat/shared/widgets/cards/hydra_card.dart';

/// Displays a single Quality of Life assessment question with response options.
///
/// Shows the question text, domain badge, 5-point response scale (4→0),
/// and a "Not sure" option. Response options are displayed as selectable cards
/// with question-specific labels (not generic scales).
class QolQuestionCard extends StatelessWidget {
  /// Creates a QoL question card.
  const QolQuestionCard({
    required this.question,
    required this.onResponseSelected,
    super.key,
    this.currentResponse,
  });

  /// The question to display.
  final QolQuestion question;

  /// Current response value (0-4 or null for "Not sure").
  final int? currentResponse;

  /// Callback when a response is selected.
  final ValueChanged<int?> onResponseSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Domain badge
        _buildDomainBadge(l10n),
        const SizedBox(height: AppSpacing.lg),

        // Question text
        _buildQuestionText(l10n),
        const SizedBox(height: AppSpacing.sm),

        // Recall period reminder
        _buildRecallPeriod(l10n),
        const SizedBox(height: AppSpacing.xl),

        // Response options (5 cards for scores 4→0)
        ..._buildResponseOptions(l10n),
        const SizedBox(height: AppSpacing.md),

        // "Not sure" option
        _buildNotSureOption(l10n),

        // Spacer at bottom
        const Spacer(),
      ],
    );
  }

  /// Builds the domain badge chip.
  Widget _buildDomainBadge(AppLocalizations l10n) {
    final domainName = _getLocalizedString(
      l10n,
      QolDomain.getDisplayNameKey(question.domain) ?? '',
    );

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(
          domainName,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }

  /// Builds the question text.
  Widget _buildQuestionText(AppLocalizations l10n) {
    return Text(
      _getLocalizedString(l10n, question.textKey),
      style: AppTextStyles.h1,
      textAlign: TextAlign.center,
    );
  }

  /// Builds the recall period reminder.
  Widget _buildRecallPeriod(AppLocalizations l10n) {
    return Text(
      l10n.qolRecallPeriod,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Builds the response option cards (scores 4 to 0, highest first).
  List<Widget> _buildResponseOptions(AppLocalizations l10n) {
    return List.generate(5, (index) {
      final score = 4 - index; // Display from best to worst (4→0)
      final isSelected = currentResponse == score;
      final labelKey = question.responseLabelKeys[score]!;
      final label = _getLocalizedString(l10n, labelKey);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: HydraCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderColor: isSelected ? AppColors.primary : AppColors.border,
          onTap: () => onResponseSelected(score),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.surface,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.surface,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Builds the "Not sure" option card.
  Widget _buildNotSureOption(AppLocalizations l10n) {
    final isSelected = currentResponse == null;

    return HydraCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: isSelected ? AppColors.textSecondary : AppColors.border,
      onTap: () => onResponseSelected(null),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.textSecondary
                    : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? AppColors.textSecondary : AppColors.surface,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.surface,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.qolNotSure,
              style: AppTextStyles.body.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get localized string from a key.
  ///
  /// Maps string keys to their corresponding AppLocalizations getters.
  /// This is necessary because the generated AppLocalizations class uses
  /// typed getters rather than a dynamic lookup method.
  String _getLocalizedString(AppLocalizations l10n, String key) {
    // Domain display names
    if (key == 'qolDomainVitality') return l10n.qolDomainVitality;
    if (key == 'qolDomainComfort') return l10n.qolDomainComfort;
    if (key == 'qolDomainEmotional') return l10n.qolDomainEmotional;
    if (key == 'qolDomainAppetite') return l10n.qolDomainAppetite;
    if (key == 'qolDomainTreatmentBurden') return l10n.qolDomainTreatmentBurden;

    // Question texts
    if (key == 'qolQuestionVitality1') return l10n.qolQuestionVitality1;
    if (key == 'qolQuestionVitality2') return l10n.qolQuestionVitality2;
    if (key == 'qolQuestionVitality3') return l10n.qolQuestionVitality3;
    if (key == 'qolQuestionComfort1') return l10n.qolQuestionComfort1;
    if (key == 'qolQuestionComfort2') return l10n.qolQuestionComfort2;
    if (key == 'qolQuestionComfort3') return l10n.qolQuestionComfort3;
    if (key == 'qolQuestionEmotional1') return l10n.qolQuestionEmotional1;
    if (key == 'qolQuestionEmotional2') return l10n.qolQuestionEmotional2;
    if (key == 'qolQuestionEmotional3') return l10n.qolQuestionEmotional3;
    if (key == 'qolQuestionAppetite1') return l10n.qolQuestionAppetite1;
    if (key == 'qolQuestionAppetite2') return l10n.qolQuestionAppetite2;
    if (key == 'qolQuestionAppetite3') return l10n.qolQuestionAppetite3;
    if (key == 'qolQuestionTreatment1') return l10n.qolQuestionTreatment1;
    if (key == 'qolQuestionTreatment2') return l10n.qolQuestionTreatment2;

    // Vitality labels
    if (key == 'qolVitality1Label0') return l10n.qolVitality1Label0;
    if (key == 'qolVitality1Label1') return l10n.qolVitality1Label1;
    if (key == 'qolVitality1Label2') return l10n.qolVitality1Label2;
    if (key == 'qolVitality1Label3') return l10n.qolVitality1Label3;
    if (key == 'qolVitality1Label4') return l10n.qolVitality1Label4;
    if (key == 'qolVitality2Label0') return l10n.qolVitality2Label0;
    if (key == 'qolVitality2Label1') return l10n.qolVitality2Label1;
    if (key == 'qolVitality2Label2') return l10n.qolVitality2Label2;
    if (key == 'qolVitality2Label3') return l10n.qolVitality2Label3;
    if (key == 'qolVitality2Label4') return l10n.qolVitality2Label4;
    if (key == 'qolVitality3Label0') return l10n.qolVitality3Label0;
    if (key == 'qolVitality3Label1') return l10n.qolVitality3Label1;
    if (key == 'qolVitality3Label2') return l10n.qolVitality3Label2;
    if (key == 'qolVitality3Label3') return l10n.qolVitality3Label3;
    if (key == 'qolVitality3Label4') return l10n.qolVitality3Label4;

    // Comfort labels
    if (key == 'qolComfort1Label0') return l10n.qolComfort1Label0;
    if (key == 'qolComfort1Label1') return l10n.qolComfort1Label1;
    if (key == 'qolComfort1Label2') return l10n.qolComfort1Label2;
    if (key == 'qolComfort1Label3') return l10n.qolComfort1Label3;
    if (key == 'qolComfort1Label4') return l10n.qolComfort1Label4;
    if (key == 'qolComfort2Label0') return l10n.qolComfort2Label0;
    if (key == 'qolComfort2Label1') return l10n.qolComfort2Label1;
    if (key == 'qolComfort2Label2') return l10n.qolComfort2Label2;
    if (key == 'qolComfort2Label3') return l10n.qolComfort2Label3;
    if (key == 'qolComfort2Label4') return l10n.qolComfort2Label4;
    if (key == 'qolComfort3Label0') return l10n.qolComfort3Label0;
    if (key == 'qolComfort3Label1') return l10n.qolComfort3Label1;
    if (key == 'qolComfort3Label2') return l10n.qolComfort3Label2;
    if (key == 'qolComfort3Label3') return l10n.qolComfort3Label3;
    if (key == 'qolComfort3Label4') return l10n.qolComfort3Label4;

    // Emotional labels
    if (key == 'qolEmotional1Label0') return l10n.qolEmotional1Label0;
    if (key == 'qolEmotional1Label1') return l10n.qolEmotional1Label1;
    if (key == 'qolEmotional1Label2') return l10n.qolEmotional1Label2;
    if (key == 'qolEmotional1Label3') return l10n.qolEmotional1Label3;
    if (key == 'qolEmotional1Label4') return l10n.qolEmotional1Label4;
    if (key == 'qolEmotional2Label0') return l10n.qolEmotional2Label0;
    if (key == 'qolEmotional2Label1') return l10n.qolEmotional2Label1;
    if (key == 'qolEmotional2Label2') return l10n.qolEmotional2Label2;
    if (key == 'qolEmotional2Label3') return l10n.qolEmotional2Label3;
    if (key == 'qolEmotional2Label4') return l10n.qolEmotional2Label4;
    if (key == 'qolEmotional3Label0') return l10n.qolEmotional3Label0;
    if (key == 'qolEmotional3Label1') return l10n.qolEmotional3Label1;
    if (key == 'qolEmotional3Label2') return l10n.qolEmotional3Label2;
    if (key == 'qolEmotional3Label3') return l10n.qolEmotional3Label3;
    if (key == 'qolEmotional3Label4') return l10n.qolEmotional3Label4;

    // Appetite labels
    if (key == 'qolAppetite1Label0') return l10n.qolAppetite1Label0;
    if (key == 'qolAppetite1Label1') return l10n.qolAppetite1Label1;
    if (key == 'qolAppetite1Label2') return l10n.qolAppetite1Label2;
    if (key == 'qolAppetite1Label3') return l10n.qolAppetite1Label3;
    if (key == 'qolAppetite1Label4') return l10n.qolAppetite1Label4;
    if (key == 'qolAppetite2Label0') return l10n.qolAppetite2Label0;
    if (key == 'qolAppetite2Label1') return l10n.qolAppetite2Label1;
    if (key == 'qolAppetite2Label2') return l10n.qolAppetite2Label2;
    if (key == 'qolAppetite2Label3') return l10n.qolAppetite2Label3;
    if (key == 'qolAppetite2Label4') return l10n.qolAppetite2Label4;
    if (key == 'qolAppetite3Label0') return l10n.qolAppetite3Label0;
    if (key == 'qolAppetite3Label1') return l10n.qolAppetite3Label1;
    if (key == 'qolAppetite3Label2') return l10n.qolAppetite3Label2;
    if (key == 'qolAppetite3Label3') return l10n.qolAppetite3Label3;
    if (key == 'qolAppetite3Label4') return l10n.qolAppetite3Label4;

    // Treatment labels
    if (key == 'qolTreatment1Label0') return l10n.qolTreatment1Label0;
    if (key == 'qolTreatment1Label1') return l10n.qolTreatment1Label1;
    if (key == 'qolTreatment1Label2') return l10n.qolTreatment1Label2;
    if (key == 'qolTreatment1Label3') return l10n.qolTreatment1Label3;
    if (key == 'qolTreatment1Label4') return l10n.qolTreatment1Label4;
    if (key == 'qolTreatment2Label0') return l10n.qolTreatment2Label0;
    if (key == 'qolTreatment2Label1') return l10n.qolTreatment2Label1;
    if (key == 'qolTreatment2Label2') return l10n.qolTreatment2Label2;
    if (key == 'qolTreatment2Label3') return l10n.qolTreatment2Label3;
    if (key == 'qolTreatment2Label4') return l10n.qolTreatment2Label4;

    // Fallback for unknown keys (should not happen in production)
    return key;
  }
}
