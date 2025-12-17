import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hydracat/core/extensions/build_context_extensions.dart';
import 'package:hydracat/core/theme/theme.dart';
import 'package:hydracat/features/qol/models/qol_assessment.dart';
import 'package:hydracat/features/qol/models/qol_question.dart';
import 'package:hydracat/features/qol/models/qol_response.dart';
import 'package:hydracat/features/qol/widgets/qol_question_card.dart';
import 'package:hydracat/providers/analytics_provider.dart';
import 'package:hydracat/providers/auth_provider.dart';
import 'package:hydracat/providers/profile_provider.dart';
import 'package:hydracat/providers/qol_provider.dart';
import 'package:hydracat/shared/widgets/buttons/hydra_button.dart';
import 'package:hydracat/shared/widgets/dialogs/hydra_alert_dialog.dart';
import 'package:hydracat/shared/widgets/feedback/hydra_snack_bar.dart';
import 'package:hydracat/shared/widgets/layout/layout.dart';

/// Questionnaire screen for QoL assessment.
///
/// Displays 14 questions one at a time with auto-advance and progress tracking.
/// Supports both new assessments and editing existing ones.
class QolQuestionnaireScreen extends ConsumerStatefulWidget {
  /// Creates a [QolQuestionnaireScreen].
  ///
  /// If [assessmentId] is provided, the screen will load the existing
  /// assessment for editing. Otherwise, it creates a new assessment.
  const QolQuestionnaireScreen({
    super.key,
    this.assessmentId,
  });

  /// Optional assessment ID for editing mode.
  ///
  /// Format: YYYY-MM-DD
  final String? assessmentId;

  @override
  ConsumerState<QolQuestionnaireScreen> createState() =>
      _QolQuestionnaireScreenState();
}

class _QolQuestionnaireScreenState
    extends ConsumerState<QolQuestionnaireScreen> {
  // Controllers
  late PageController _pageController;

  // State
  final Map<String, int?> _responses = {};
  late DateTime _selectedDate;
  late DateTime _startTime;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _selectedDate = DateTime.now();
    _startTime = DateTime.now();

    // Track assessment started
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final petId = ref.read(primaryPetProvider)?.id;
      ref.read(analyticsServiceDirectProvider).trackQolAssessmentStarted(
            petId: petId,
          );
    });

    // Load existing assessment if editing
    if (widget.assessmentId != null) {
      _loadExistingAssessment();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Loads existing assessment for editing.
  Future<void> _loadExistingAssessment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assessments = ref.read(recentQolAssessmentsProvider);
      final assessment = assessments.firstWhere(
        (a) => a.documentId == widget.assessmentId,
        orElse: () => throw Exception('Assessment not found'),
      );

      // Pre-fill responses
      setState(() {
        for (final response in assessment.responses) {
          _responses[response.questionId] = response.score;
        }
        _selectedDate = assessment.date;
        _isLoading = false;
      });
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showError('Failed to load assessment');
      }
    }
  }

  /// Handles response selection with auto-advance.
  void _handleResponseSelected(String questionId, int? score) {
    setState(() {
      _responses[questionId] = score;
    });

    // Haptic feedback
    HapticFeedback.selectionClick();

    // Track question answered
    final question = QolQuestion.all.firstWhere((q) => q.id == questionId);
    final petId = ref.read(primaryPetProvider)?.id;
    ref.read(analyticsServiceDirectProvider).trackQolQuestionAnswered(
          questionId: questionId,
          domain: question.domain,
          score: score,
          petId: petId,
        );

    // Auto-advance after 300ms (unless last question)
    if (_currentQuestionIndex < 13) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  /// Saves the assessment.
  Future<void> _saveAssessment() async {
    final user = ref.read(currentUserProvider);
    final pet = ref.read(primaryPetProvider);

    if (user == null || pet == null) {
      _showError('User or pet not found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate completion duration
      final completionDuration = DateTime.now().difference(_startTime);

      // Build responses list
      final responses = QolQuestion.all.map((question) {
        return QolResponse(
          questionId: question.id,
          score: _responses[question.id],
        );
      }).toList();

      // Create assessment
      final assessment = widget.assessmentId != null
          ? _createEditedAssessment(user.id, pet.id, responses)
          : _createNewAssessment(
              user.id,
              pet.id,
              responses,
              completionDuration.inSeconds,
            );

      // Save via provider
      if (widget.assessmentId != null) {
        await ref.read(qolProvider.notifier).updateAssessment(assessment);
      } else {
        await ref.read(qolProvider.notifier).saveAssessment(assessment);
      }

      if (mounted) {
        // Navigate to detail screen
        context.go('/profile/qol/detail/${assessment.documentId}');
      }
    } on Exception {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        HydraSnackBar.showError(context, context.l10n.qolSaveError);
      }
    }
  }

  /// Creates a new assessment.
  QolAssessment _createNewAssessment(
    String userId,
    String petId,
    List<QolResponse> responses,
    int durationSeconds,
  ) {
    return QolAssessment.empty(
      userId: userId,
      petId: petId,
      date: _selectedDate,
    ).copyWith(
      responses: responses,
      completionDurationSeconds: durationSeconds,
    );
  }

  /// Creates an edited assessment.
  QolAssessment _createEditedAssessment(
    String userId,
    String petId,
    List<QolResponse> responses,
  ) {
    final existing = ref.read(recentQolAssessmentsProvider).firstWhere(
          (a) => a.documentId == widget.assessmentId,
        );

    return existing.copyWith(
      responses: responses,
      updatedAt: DateTime.now(),
      completionDurationSeconds: null, // Edited assessments lose duration
    );
  }

  /// Shows error message.
  void _showError(String message) {
    HydraSnackBar.showError(context, message);
  }

  /// Confirms discard if answers exist.
  Future<bool> _confirmDiscard() async {
    final answeredCount = _responses.values.where((v) => v != null).length;

    // Allow exit if no answers
    if (answeredCount == 0) {
      return true;
    }

    // Show confirmation dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => HydraAlertDialog(
        title: Text(context.l10n.qolDiscardTitle),
        content: Text(context.l10n.qolDiscardMessage(answeredCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.qolKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.discard),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isEdit = widget.assessmentId != null;
    final isSaving = ref.watch(isSavingQolProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: AppScaffold(
        title: isEdit
            ? l10n.qolQuestionnaireEditTitle
            : l10n.qolQuestionnaireTitle,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldPop = await _confirmDiscard();
            if (shouldPop && context.mounted) {
              context.pop();
            }
          },
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / 14,
                    backgroundColor: AppColors.border,
                    color: AppColors.primary,
                    minHeight: 4,
                  ),

                  // PageView with questions
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      },
                      itemCount: QolQuestion.all.length,
                      itemBuilder: (context, index) {
                        final question = QolQuestion.all[index];
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: QolQuestionCard(
                            question: question,
                            currentResponse: _responses[question.id],
                            onResponseSelected: (score) {
                              _handleResponseSelected(question.id, score);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom navigation bar
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          // Previous button
                          if (_currentQuestionIndex > 0)
                            Expanded(
                              child: HydraButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                variant: HydraButtonVariant.secondary,
                                child: Text(l10n.previous),
                              ),
                            ),

                          if (_currentQuestionIndex > 0)
                            const SizedBox(width: AppSpacing.md),

                          // Complete button (on last question)
                          if (_currentQuestionIndex == 13)
                            Expanded(
                              child: HydraButton(
                                onPressed: isSaving ? null : _saveAssessment,
                                isLoading: isSaving,
                                child: Text(l10n.qolComplete),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
