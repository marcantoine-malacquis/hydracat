import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/health/widgets/symptoms_entry_dialog.dart';
import 'package:hydracat/features/logging/services/overlay_service.dart';
import 'package:hydracat/shared/widgets/widgets.dart';

/// Screen for viewing and managing symptom tracking
///
/// Features (V1):
/// - Empty state for first-time users
/// - FAB for adding new symptom entries
/// - Minimal implementation - no charts/trends yet
class SymptomsScreen extends ConsumerStatefulWidget {
  /// Creates a [SymptomsScreen]
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  ScrollController? _scrollController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;

    final direction = _scrollController!.position.userScrollDirection;

    // Hide FAB when scrolling down
    if (direction == ScrollDirection.reverse) {
      if (_showFab) {
        setState(() {
          _showFab = false;
        });
      }
    }
    // Show FAB when scrolling up
    else if (direction == ScrollDirection.forward) {
      if (!_showFab) {
        setState(() {
          _showFab = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  void _showAddSymptomsDialog() {
    OverlayService.showFullScreenPopup(
      context: context,
      child: const SymptomsEntryDialog(),
      onDismiss: () {
        // No special cleanup needed
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: HydraAppBar(
        title: const Text('Symptoms'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios),
          iconSize: 20,
          color: AppColors.textSecondary,
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: _buildEmptyState(),
      ),
      floatingActionButton: _showFab
          ? HydraExtendedFab(
              onPressed: _showAddSymptomsDialog,
              icon: Icons.add,
              label: 'Add Symptoms',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              useGlassEffect: true,
            )
          : null,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: 80,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              "Track Your Pet's Symptoms",
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Monitor daily symptoms to help manage your pet's CKD. "
              'Tracking symptoms like vomiting, diarrhea, and lethargy helps '
              'you and your vet identify patterns and adjust treatment.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
