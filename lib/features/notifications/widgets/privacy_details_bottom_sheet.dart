import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/l10n/app_localizations.dart';
import 'package:markdown_widget/markdown_widget.dart';

/// Bottom sheet that displays the full notification privacy policy.
///
/// Loads and renders the privacy policy from `assets/legal/notification_privacy.md`
/// using the markdown_widget package. Supports dark/light mode theming.
///
/// Features:
/// - Scrollable content for long policy document
/// - Material Design bottom sheet with rounded top corners
/// - Dark mode support with appropriate markdown config
/// - Error handling if markdown fails to load
/// - Close button in header for easy dismissal
///
/// Example usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => const PrivacyDetailsBottomSheet(),
/// );
/// ```
class PrivacyDetailsBottomSheet extends StatefulWidget {
  /// Creates a privacy details bottom sheet.
  const PrivacyDetailsBottomSheet({super.key});

  @override
  State<PrivacyDetailsBottomSheet> createState() =>
      _PrivacyDetailsBottomSheetState();
}

class _PrivacyDetailsBottomSheetState extends State<PrivacyDetailsBottomSheet> {
  String? _markdownContent;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  /// Loads the privacy policy markdown from assets
  Future<void> _loadPrivacyPolicy() async {
    try {
      final content = await rootBundle.loadString(
        'assets/legal/notification_privacy.md',
      );

      if (mounted) {
        setState(() {
          _markdownContent = content;
          _isLoading = false;
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with title and close button
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.notificationPrivacyBottomSheetTitle,
                    style: AppTextStyles.h2,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(context, l10n, isDark),
          ),
        ],
      ),
    );
  }

  /// Builds the main content area with loading, error, or markdown
  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    bool isDark,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.notificationPrivacyLoadError,
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadPrivacyPolicy();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Display markdown content
    // Note: Using MarkdownBlock (not MarkdownWidget) because we're inside
    // a SingleChildScrollView. MarkdownWidget manages its own scrolling
    // which causes rendering conflicts.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: MarkdownBlock(
        data: _markdownContent ?? '',
        config: isDark
            ? MarkdownConfig.darkConfig
            : MarkdownConfig.defaultConfig,
      ),
    );
  }
}
