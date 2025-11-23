import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Demo screen to showcase all HydraCat components.
/// This screen demonstrates the water theme implementation.
class ComponentDemoScreen extends StatefulWidget {
  /// Creates a ComponentDemoScreen.
  const ComponentDemoScreen({super.key});

  @override
  State<ComponentDemoScreen> createState() => _ComponentDemoScreenState();
}

class _ComponentDemoScreenState extends State<ComponentDemoScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HydraAppBar(
        title: Text('HydraCat Components'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Typography System'),
            _buildTypographyDemo(),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Color Palette'),
            _buildColorDemo(),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Button Components'),
            _buildButtonDemo(),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Card Components'),
            _buildCardDemo(),

            const SizedBox(height: AppSpacing.xl),
            _buildSectionTitle('Navigation Bar'),
            _buildNavigationDemo(),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.h2.copyWith(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTypographyDemo() {
    return const HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display Text', style: AppTextStyles.display),
          SizedBox(height: AppSpacing.sm),
          Text('H1 Heading', style: AppTextStyles.h1),
          SizedBox(height: AppSpacing.sm),
          Text('H2 Heading', style: AppTextStyles.h2),
          SizedBox(height: AppSpacing.sm),
          Text('H3 Heading', style: AppTextStyles.h3),
          SizedBox(height: AppSpacing.sm),
          Text('Body Text', style: AppTextStyles.body),
          SizedBox(height: AppSpacing.sm),
          Text('Caption Text', style: AppTextStyles.caption),
          SizedBox(height: AppSpacing.sm),
          Text('Small Text', style: AppTextStyles.small),
        ],
      ),
    );
  }

  Widget _buildColorDemo() {
    return Column(
      children: [
        _buildColorRow('Primary', AppColors.primary),
        _buildColorRow('Primary Light', AppColors.primaryLight),
        _buildColorRow('Primary Dark', AppColors.primaryDark),
        _buildColorRow('Success', AppColors.success),
        _buildColorRow('Warning', AppColors.warning),
        _buildColorRow('Error', AppColors.error),
        _buildColorRow('Background', AppColors.background),
        _buildColorRow('Surface', AppColors.surface),
      ],
    );
  }

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$name: ${color.toARGB32().toRadixString(16).toUpperCase()}',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonDemo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: HydraButton(
                onPressed: () {},
                child: const Text('Primary'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: HydraButton(
                onPressed: () {},
                variant: HydraButtonVariant.secondary,
                child: const Text('Secondary'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: HydraButton(
                onPressed: () {},
                variant: HydraButtonVariant.text,
                child: const Text('Text'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: HydraButton(
                onPressed: () {},
                isLoading: _isLoading,
                child: const Text('Loading'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        HydraButton(
          onPressed: () {
            setState(() {
              _isLoading = !_isLoading;
            });
          },
          isFullWidth: true,
          child: Text(_isLoading ? 'Stop Loading' : 'Toggle Loading'),
        ),
      ],
    );
  }

  Widget _buildCardDemo() {
    return Column(
      children: [
        const HydraCard(
          child: Text('Basic Card'),
        ),
        const SizedBox(height: AppSpacing.md),
        HydraSectionCard(
          title: 'Section Card',
          subtitle: 'With subtitle and actions',
          actions: [
            HydraButton(
              onPressed: () {},
              variant: HydraButtonVariant.text,
              size: HydraButtonSize.small,
              child: const Text('Action'),
            ),
          ],
          child: const Text('Section content goes here'),
        ),
        const SizedBox(height: AppSpacing.md),
        HydraInfoCard(
          message: 'This is an informational message',
          actions: [
            HydraButton(
              onPressed: () {},
              variant: HydraButtonVariant.text,
              size: HydraButtonSize.small,
              child: const Text('Dismiss'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const HydraInfoCard(
          message: 'Success! Operation completed successfully.',
          type: HydraInfoType.success,
        ),
        const SizedBox(height: AppSpacing.md),
        const HydraInfoCard(
          message: 'Warning: Please check your input.',
          type: HydraInfoType.warning,
        ),
        const SizedBox(height: AppSpacing.md),
        const HydraInfoCard(
          message: 'Error: Something went wrong.',
          type: HydraInfoType.error,
        ),
      ],
    );
  }

  Widget _buildNavigationDemo() {
    return HydraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Navigation Bar Demo',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'The navigation bar is now handled by the AppShell and provides '
            'consistent navigation across all screens with the droplet FAB.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Current Index: 0',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
