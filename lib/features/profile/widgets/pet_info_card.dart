import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydracat/core/constants/app_icons.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/core/utils/date_utils.dart';
import 'package:hydracat/core/utils/weight_utils.dart';
import 'package:hydracat/features/profile/models/cat_profile.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/weight_unit_provider.dart';
import 'package:hydracat/shared/widgets/icons/hydra_icon.dart';

/// A card widget displaying pet information with photo placeholder
///
/// Shows pet name, gender, age, breed, and weight in a compact layout
/// with a circular photo placeholder on the left.
class PetInfoCard extends ConsumerWidget {
  /// Creates a [PetInfoCard]
  const PetInfoCard({
    required this.pet,
    required this.isRefreshing,
    this.cacheStatus,
    this.lastUpdated,
    super.key,
  });

  /// The pet profile to display
  final CatProfile pet;

  /// Whether the data is currently being refreshed
  final bool isRefreshing;

  /// Cache status for offline indicator
  final CacheStatus? cacheStatus;

  /// Last time the data was updated
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cache status indicator (if stale or offline)
          if (cacheStatus == CacheStatus.stale && lastUpdated != null) ...[
            _buildCacheStatusIndicator(context),
            const SizedBox(height: AppSpacing.md),
          ],

          // Main content: Photo + Pet info
          _buildMainContent(context, ref),
        ],
      ),
    );
  }

  /// Builds the cache status indicator for offline mode
  Widget _buildCacheStatusIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          HydraIcon(
            icon: AppIcons.wifiOff,
            size: 14,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'Offline – last updated '
              '${AppDateUtils.getRelativeTimeCompact(lastUpdated!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main content with photo placeholder and pet information
  Widget _buildMainContent(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Photo placeholder
        _buildPhotoPlaceholder(context),

        const SizedBox(width: AppSpacing.lg),

        // Right: Pet information
        Expanded(
          child: _buildPetInfo(context, ref),
        ),
      ],
    );
  }

  /// Builds the circular photo placeholder with paw icon
  Widget _buildPhotoPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        color: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: const Center(
        child: HydraIcon(
          icon: AppIcons.petProfile,
          size: 40,
          color: AppColors.primary,
        ),
      ),
    );
  }

  /// Builds the pet information section (3 lines)
  Widget _buildPetInfo(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Line 1: Name + Gender symbol
        _buildNameAndGender(context),

        const SizedBox(height: AppSpacing.xs),

        // Line 2: Age (with birthdate if available)
        _buildAge(context),

        const SizedBox(height: AppSpacing.xs),

        // Line 3: Breed + Weight (conditional)
        _buildBreedAndWeight(context, ref),
      ],
    );
  }

  /// Builds the name and gender symbol line
  Widget _buildNameAndGender(BuildContext context) {
    // Get gender symbol
    final genderSymbol = _getGenderSymbol(pet.gender);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: pet.name,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (genderSymbol != null) ...[
            TextSpan(
              text: ' $genderSymbol',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Builds the age line with optional birthdate
  Widget _buildAge(BuildContext context) {
    final ageText = AppDateUtils.formatAgeWithBirthdate(
      pet.ageYears,
      pet.dateOfBirth,
    );

    return Text(
      ageText,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Builds the breed and weight line (conditional)
  Widget _buildBreedAndWeight(BuildContext context, WidgetRef ref) {
    final weightUnit = ref.watch(weightUnitProvider);
    final weightText = WeightUtils.formatWeight(pet.weightKg, weightUnit);

    // Build the line based on breed availability
    final hasBreed = pet.breed != null && pet.breed!.isNotEmpty;

    final displayText = hasBreed ? '${pet.breed} • $weightText' : weightText;

    return Text(
      displayText,
      style: AppTextStyles.body.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Gets the gender symbol for display
  ///
  /// Returns:
  /// - ♂ for male
  /// - ♀ for female
  /// - null for unknown/missing gender
  String? _getGenderSymbol(String? gender) {
    if (gender == null || gender.isEmpty) {
      return null;
    }

    switch (gender.toLowerCase()) {
      case 'male':
        return '♂';
      case 'female':
        return '♀';
      default:
        return null;
    }
  }
}
