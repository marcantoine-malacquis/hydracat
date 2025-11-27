import 'package:flutter/material.dart';
import 'package:hydracat/core/constants/app_colors.dart';
import 'package:hydracat/shared/widgets/bottom_sheets/bottom_sheets.dart';

/// Shared helper for showing logging bottom sheets consistently across the app.
///
/// This ensures that medication and fluid logging screens are presented
/// with the same configuration (background, scroll behavior) whether
/// opened from the FAB, notifications, or the home dashboard.
///
/// The bottom sheet will size to its content (up to 85% max height) via
/// LoggingPopupWrapper's ConstrainedBox, with proper bottom spacing handled
/// by HydraBottomSheet's SafeArea.
Future<void> showLoggingBottomSheet(
  BuildContext context,
  Widget child,
) {
  return showHydraBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    builder: (sheetContext) => HydraBottomSheet(
      backgroundColor: AppColors.background,
      child: child,
    ),
  );
}
