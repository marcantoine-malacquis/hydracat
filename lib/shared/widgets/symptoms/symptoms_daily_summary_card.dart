import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_text_styles.dart';
import 'package:hydracat/shared/models/symptoms_daily_summary_view.dart';

/// Card displaying symptoms logged for a specific day
class SymptomsDailySummaryCard extends StatelessWidget {
  /// Creates a symptoms daily summary card
  const SymptomsDailySummaryCard({
    required this.summary,
    this.padding,
    super.key,
  });

  /// Daily symptom data to render
  final SymptomsDailySummaryView summary;

  /// Optional padding for the outer container
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Symptoms',
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List of symptoms
            ...summary.symptoms.asMap().entries.map((entry) {
              final index = entry.key;
              final symptom = entry.value;
              final isLast = index == summary.symptoms.length - 1;

              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
                child: Semantics(
                  label: '${symptom.label}: ${symptom.descriptor}',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Symptom label (left side)
                      Text(
                        symptom.label,
                        style: AppTextStyles.small.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Descriptor (right side)
                      Text(
                        symptom.descriptor,
                        style: AppTextStyles.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
