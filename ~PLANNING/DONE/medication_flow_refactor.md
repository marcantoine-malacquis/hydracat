# Add Medication Flow Refactor - Hydra Components Integration
## Implementation Plan

## Overview
Refactor the "add medication" multi-step flow to utilize platform-specific Hydra components, providing a modern bottom sheet presentation with smooth slide animations, consistent with HydraCat's design system.

The refactored flow will replace the current centered dialog approach with a mobile-first bottom sheet that slides up from the bottom, featuring smooth horizontal slide transitions between steps, an animated progress indicator, and comprehensive validation with user-friendly feedback.

## Design Philosophy
- **Mobile-First**: Bottom sheet presentation aligns with modern mobile UI patterns
- **Smooth Transitions**: Elegant slide animations between steps create visual continuity
- **Platform Consistency**: All components use Hydra widgets for Material/Cupertino adaptation
- **Progressive Validation**: Validate on step advancement, provide real-time feedback for corrections
- **Safety First**: Warn users about unsaved changes before dismissal
- **Accessible**: Proper keyboard handling, touch targets, and reduce motion support

---

## User Experience Requirements

### Flow Structure (Unchanged)
The 4-step flow remains the same:
1. **Medication Details**: Name + Strength (optional)
2. **Dosage**: Amount per administration + Unit
3. **Frequency**: How often medication is given
4. **Reminder Times**: Schedule reminder notifications

### Visual & Interaction Changes

#### Bottom Sheet Presentation
- **Entry Animation**: Slides up from bottom (200ms, easeOut)
- **Height**: 85% of screen height (`heightFraction: 0.85`)
- **Dismissal**:
  - Swipe down gesture enabled
  - Tap outside to dismiss (with unsaved changes warning)
  - Cancel button in header
- **Background**: Semi-transparent backdrop (40% opacity)
- **Rounded Corners**: 16px top corners (from `AppBorderRadius.dialog`)

#### Step Navigation
- **Horizontal Slide Animation**:
  - Next: Right-to-left slide (260ms)
  - Previous: Left-to-right slide (260ms)
  - Subtle fade component (25% fade-in at start, 25% fade-out at end)
  - Curve: `Curves.easeInOut` (from `AppAnimations.pageSlideCurve`)
- **Button State**: Navigation buttons disabled during animation
- **PageView**: Swipe gestures disabled (button-only navigation)

#### Animated Progress Indicator
- **Design**: Horizontal row of 4 circles with connecting lines
- **States**:
  - **Completed Step**: Filled circle with checkmark icon, teal fill
  - **Active Step**: Filled circle with step number, teal fill, subtle scale pulse
  - **Pending Step**: Outlined circle with step number, gray outline
- **Connecting Lines**:
  - Completed: Teal fill
  - Pending: Gray fill
- **Animations**:
  - Circle fill: 200ms ease-in when step becomes active
  - Line extension: 200ms ease-out when advancing
  - Checkmark fade-in: 150ms when step is completed
  - Active step pulse: Subtle scale (1.0 → 1.05 → 1.0) on activation

#### Header Layout
```
┌─────────────────────────────────────────────┐
│  [Step Title]                          [×]  │  ← Header (60px height)
│  ○──○──○──○  Step 1 of 4                   │  ← Progress indicator
├─────────────────────────────────────────────┤
│                                             │
│         [Step Content - Scrollable]         │
│                                             │
│                                             │
├─────────────────────────────────────────────┤
│  [Previous]              [Next/Save]        │  ← Footer (70px height)
└─────────────────────────────────────────────┘
```

#### Validation & Feedback
- **Timing**: Validation occurs when user taps Next
- **Display**: Errors shown in `HydraTextFormField` error text
- **Real-time**: After first validation attempt, show live feedback as user corrects
- **Button State**: Next button disabled when current step is invalid
- **Visual Cue**: Disabled button has reduced opacity (60%)

#### Unsaved Changes Warning
When user attempts to dismiss (swipe, tap outside, or cancel button) with unsaved changes:
```
┌─────────────────────────────────────┐
│  Discard Changes?                   │
│                                     │
│  You have unsaved changes. Are     │
│  you sure you want to discard      │
│  them?                              │
│                                     │
│  [Cancel]        [Discard]          │
└─────────────────────────────────────┘
```

---

## Technical Architecture

### Component Hierarchy (Refactored)

```
AddMedicationBottomSheet (NEW)
├── HydraBottomSheet
│   └── Column
│       ├── _Header
│       │   ├── Text (title)
│       │   └── TouchTargetIconButton (close)
│       ├── _AnimatedProgressIndicator (NEW)
│       │   └── Row (circles + lines with animations)
│       ├── Expanded
│       │   └── _AnimatedPageView (NEW)
│       │       └── PageView.builder
│       │           ├── _StepOne (name + strength)
│       │           │   ├── HydraTextFormField (name)
│       │           │   └── Row
│       │           │       ├── HydraTextFormField (strength amount)
│       │           │       └── HydraDropdown (strength unit)
│       │           ├── _StepTwo (dosage + unit)
│       │           │   └── Row
│       │           │       ├── HydraTextFormField (dosage)
│       │           │       └── HydraDropdown (unit)
│       │           ├── _StepThree (frequency)
│       │           │   └── RotatingWheelPicker (existing)
│       │           └── _StepFour (reminder times)
│       │               └── TimePickerGroup (existing)
│       └── _Footer
│           ├── HydraButton.secondary (Previous)
│           └── HydraButton.primary (Next/Save)
```

### Data Flow

```
User Interaction
       ↓
AddMedicationBottomSheet (state management)
       ↓
PageController (step navigation)
       ↓
Form Controllers (data capture)
       ↓
Validation Logic (step-specific)
       ↓
MedicationData (on save)
       ↓
Parent Callback (onSave)
```

### Animation Architecture

#### Step Transition Animation
```dart
// Custom PageView transitionsBuilder
AnimatedBuilder(
  animation: pageController,
  builder: (context, child) {
    // Calculate offset based on page position
    final offset = (pageController.page ?? 0) - index;

    return Transform.translate(
      offset: Offset(offset * screenWidth, 0),
      child: Opacity(
        opacity: _calculateOpacity(offset),
        child: child,
      ),
    );
  },
)
```

#### Progress Indicator Animations
```dart
// Circle state transition
AnimatedContainer(
  duration: 200ms,
  decoration: BoxDecoration(
    color: isActive ? primary : outline,
    shape: BoxShape.circle,
  ),
  child: AnimatedSwitcher(
    duration: 150ms,
    child: isCompleted ? Icon(check) : Text(number),
  ),
)

// Connecting line extension
AnimatedContainer(
  duration: 200ms,
  width: isCompleted ? 16px : 0px,
  color: primary,
)
```

### Keyboard Handling

The `HydraBottomSheet` already handles keyboard visibility via:
```dart
Padding(
  padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
  child: content,
)
```

Each step content is wrapped in `SingleChildScrollView` to ensure all inputs remain accessible when keyboard appears.

### State Management

```dart
class _AddMedicationBottomSheetState extends State<AddMedicationBottomSheet> {
  // Controllers
  late PageController _pageController;
  late List<TextEditingController> _textControllers;

  // State
  int _currentStep = 0;
  bool _isAnimating = false;
  bool _hasUnsavedChanges = false;
  Map<int, String?> _stepErrors = {};

  // Form Data
  late MedicationFormData _formData;

  // Navigation
  Future<void> _goToNextStep() async {
    if (_isAnimating) return;

    // Validate current step
    final error = _validateStep(_currentStep);
    if (error != null) {
      setState(() => _stepErrors[_currentStep] = error);
      return;
    }

    setState(() {
      _isAnimating = true;
      _stepErrors.remove(_currentStep);
    });

    await _pageController.animateToPage(
      _currentStep + 1,
      duration: AppAnimations.pageSlideDuration,
      curve: AppAnimations.pageSlideCurve,
    );

    setState(() {
      _currentStep++;
      _isAnimating = false;
    });
  }

  Future<bool> _handleDismiss() async {
    if (!_hasUnsavedChanges) return true;

    final shouldDiscard = await showHydraDialog<bool>(
      context: context,
      builder: (context) => _UnsavedChangesDialog(),
    );

    return shouldDiscard ?? false;
  }
}
```

---

## Implementation Phases

### Phase 1: Create New Bottom Sheet Component Structure

**Goal**: Set up the base bottom sheet structure with header, footer, and content area.

#### Step 1.1: Create `AddMedicationBottomSheet` Widget File
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create new stateful widget `AddMedicationBottomSheet`
- Define constructor with same parameters as current `AddMedicationScreen`:
  - `initialMedication`, `isEditing`, `onSave`, `onCancel`, `onFormChanged`
- Initialize state variables:
  - `PageController _pageController`
  - `int _currentStep = 0`
  - `bool _isAnimating = false`
  - `bool _hasUnsavedChanges = false`
  - Form controllers (same as current implementation)
- Add `showAddMedicationBottomSheet` helper function

**Code Structure**:
```dart
/// Shows the add/edit medication bottom sheet
Future<MedicationData?> showAddMedicationBottomSheet({
  required BuildContext context,
  MedicationData? initialMedication,
  bool isEditing = false,
}) {
  return showHydraBottomSheet<MedicationData>(
    context: context,
    isScrollControlled: true,
    isDismissible: false, // Handle dismissal manually
    enableDrag: true,
    builder: (context) => AddMedicationBottomSheet(
      initialMedication: initialMedication,
      isEditing: isEditing,
    ),
  );
}

class AddMedicationBottomSheet extends StatefulWidget {
  const AddMedicationBottomSheet({
    this.initialMedication,
    this.isEditing = false,
    super.key,
  });

  final MedicationData? initialMedication;
  final bool isEditing;

  @override
  State<AddMedicationBottomSheet> createState() =>
      _AddMedicationBottomSheetState();
}
```

#### Step 1.2: Implement Base Layout Structure
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `build()` method with `HydraBottomSheet` wrapper
- Set `heightFraction: 0.85`
- Add `WillPopScope` for handling back button with unsaved changes
- Create three main sections:
  - `_buildHeader()` - Title and close button
  - `_buildContent()` - PageView container (placeholder for now)
  - `_buildFooter()` - Navigation buttons

**Code Structure**:
```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: _handleWillPop,
    child: HydraBottomSheet(
      heightFraction: 0.85,
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: AppSpacing.md),
          // Progress indicator will go here
          Expanded(child: _buildContent(context)),
          _buildFooter(context),
        ],
      ),
    ),
  );
}

Widget _buildHeader(BuildContext context) {
  final l10n = context.l10n;
  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            _getStepTitle(l10n),
            style: AppTextStyles.h2,
          ),
        ),
        TouchTargetIconButton(
          icon: HydraIcon(
            icon: AppIcons.close,
            size: 24,
          ),
          onPressed: _handleClosePressed,
          semanticLabel: l10n.close,
        ),
      ],
    ),
  );
}
```

#### Step 1.3: Implement Unsaved Changes Handling
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_handleWillPop()` method
- Create `_handleClosePressed()` method
- Create `_showUnsavedChangesDialog()` method
- Track unsaved changes via `_hasUnsavedChanges` flag
- Update flag when any form field changes

**Code Structure**:
```dart
Future<bool> _handleWillPop() async {
  if (!_hasUnsavedChanges) return true;
  final shouldClose = await _showUnsavedChangesDialog();
  return shouldClose ?? false;
}

Future<void> _handleClosePressed() async {
  if (!_hasUnsavedChanges) {
    Navigator.of(context).pop();
    return;
  }

  final shouldClose = await _showUnsavedChangesDialog();
  if (shouldClose == true && mounted) {
    Navigator.of(context).pop();
  }
}

Future<bool?> _showUnsavedChangesDialog() {
  final l10n = context.l10n;
  return showHydraDialog<bool>(
    context: context,
    builder: (context) => HydraAlertDialog(
      title: Text(l10n.discardChanges),
      content: Text(l10n.discardChangesMessage),
      actions: [
        HydraButton(
          onPressed: () => Navigator.of(context).pop(false),
          variant: HydraButtonVariant.text,
          child: Text(l10n.cancel),
        ),
        HydraButton(
          onPressed: () => Navigator.of(context).pop(true),
          variant: HydraButtonVariant.primary,
          borderColor: AppColors.error,
          child: Text(l10n.discard),
        ),
      ],
    ),
  );
}
```

**Localization Additions** (`lib/l10n/app_en.arb`):
```json
"discardChanges": "Discard Changes?",
"discardChangesMessage": "You have unsaved changes. Are you sure you want to discard them?",
"discard": "Discard"
```

---

### Phase 2: Create Animated Progress Indicator

**Goal**: Build the visual progress indicator with smooth animations.

#### Step 2.1: Create Progress Indicator Widget
**File**: `lib/features/onboarding/widgets/medication_step_progress_indicator.dart`

**Tasks**:
- Create stateless widget `MedicationStepProgressIndicator`
- Accept parameters: `currentStep`, `totalSteps`
- Implement circle rendering logic with three states
- Implement connecting line rendering
- Add step count text on the right

**Code Structure**:
```dart
/// Animated progress indicator for multi-step medication form
class MedicationStepProgressIndicator extends StatelessWidget {
  const MedicationStepProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  /// Current step (0-indexed)
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(totalSteps, (index) {
                return _buildStepIndicator(context, index);
              }),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            'Step ${currentStep + 1} of $totalSteps',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context, int index) {
    final isCompleted = index < currentStep;
    final isActive = index == currentStep;
    final isPending = index > currentStep;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepCircle(
          stepNumber: index + 1,
          isCompleted: isCompleted,
          isActive: isActive,
        ),
        if (index < totalSteps - 1)
          _ConnectingLine(isCompleted: isCompleted),
      ],
    );
  }
}
```

#### Step 2.2: Create Animated Step Circle Widget
**File**: `lib/features/onboarding/widgets/medication_step_progress_indicator.dart`

**Tasks**:
- Create `_StepCircle` widget
- Implement three visual states with `AnimatedContainer`
- Add checkmark for completed state with `AnimatedSwitcher`
- Add subtle pulse animation for active state
- Use proper colors from `AppColors`

**Code Structure**:
```dart
class _StepCircle extends StatefulWidget {
  const _StepCircle({
    required this.stepNumber,
    required this.isCompleted,
    required this.isActive,
  });

  final int stepNumber;
  final bool isCompleted;
  final bool isActive;

  @override
  State<_StepCircle> createState() => _StepCircleState();
}

class _StepCircleState extends State<_StepCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StepCircle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = 28.0;

    Widget circleContent = AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: widget.isCompleted
          ? HydraIcon(
              key: const ValueKey('check'),
              icon: AppIcons.completed,
              size: 16,
              color: AppColors.onPrimary,
            )
          : Text(
              key: ValueKey('number_${widget.stepNumber}'),
              widget.stepNumber.toString(),
              style: AppTextStyles.caption.copyWith(
                color: widget.isActive
                    ? AppColors.onPrimary
                    : AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
    );

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isCompleted || widget.isActive
            ? AppColors.primary
            : Colors.transparent,
        border: Border.all(
          color: widget.isCompleted || widget.isActive
              ? AppColors.primary
              : AppColors.border,
          width: 2,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(child: circleContent),
    );

    if (widget.isActive) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: circle,
      );
    }

    return circle;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
```

#### Step 2.3: Create Animated Connecting Line Widget
**File**: `lib/features/onboarding/widgets/medication_step_progress_indicator.dart`

**Tasks**:
- Create `_ConnectingLine` widget
- Animate line color change when step completes
- Use `AnimatedContainer` for smooth transitions

**Code Structure**:
```dart
class _ConnectingLine extends StatelessWidget {
  const _ConnectingLine({
    required this.isCompleted,
  });

  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: 20,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
```

#### Step 2.4: Integrate Progress Indicator into Bottom Sheet
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Import `MedicationStepProgressIndicator`
- Add indicator between header and content
- Pass `currentStep` and `totalSteps` (4)
- Ensure indicator updates when step changes

**Code Change**:
```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: _handleWillPop,
    child: HydraBottomSheet(
      heightFraction: 0.85,
      child: Column(
        children: [
          _buildHeader(context),
          MedicationStepProgressIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
          Expanded(child: _buildContent(context)),
          _buildFooter(context),
        ],
      ),
    ),
  );
}
```

---

### Phase 3: Implement Animated PageView with Step Content

**Goal**: Create the PageView with custom slide animations and integrate existing step widgets.

#### Step 3.1: Create Custom Page Transition Builder
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_buildContent()` method with PageView
- Disable physics (no swipe gestures)
- Create custom `_buildPageTransition()` method
- Implement slide + fade animation logic

**Code Structure**:
```dart
Widget _buildContent(BuildContext context) {
  return PageView.builder(
    controller: _pageController,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _totalSteps,
    onPageChanged: (index) {
      setState(() => _currentStep = index);
    },
    itemBuilder: (context, index) {
      return AnimatedBuilder(
        animation: _pageController,
        builder: (context, child) {
          double value = 0;
          if (_pageController.position.haveDimensions) {
            value = (_pageController.page ?? 0) - index;
          }

          return _buildPageTransition(
            child: child!,
            position: value,
          );
        },
        child: _buildStepContent(index),
      );
    },
  );
}

Widget _buildPageTransition({
  required Widget child,
  required double position,
}) {
  // Calculate slide offset (full screen width)
  final offset = Offset(position, 0);

  // Calculate opacity for fade effect
  // Fade out: 1.0 → 0.0 (when swiping away)
  // Fade in: 0.0 → 1.0 (when entering)
  double opacity;
  if (position.abs() <= 1.0) {
    // Within one page distance
    opacity = 1.0 - position.abs().clamp(0.0, 0.25) * 4;
  } else {
    opacity = 0.0;
  }

  return Transform.translate(
    offset: offset * MediaQuery.of(context).size.width,
    child: Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: child,
    ),
  );
}
```

#### Step 3.2: Migrate Step Content Widgets
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Extract current step build methods from `AddMedicationScreen`
- Wrap each in `_StepWrapper` for consistent padding and scrolling
- Update to use `HydraTextFormField` instead of `TextFormField`
- Keep existing logic for `RotatingWheelPicker` and `TimePickerGroup`

**Code Structure**:
```dart
Widget _buildStepContent(int step) {
  return _StepWrapper(
    child: switch (step) {
      0 => _buildNameAndStrengthStep(),
      1 => _buildDosageStep(),
      2 => _buildFrequencyStep(),
      3 => _buildReminderTimesStep(),
      _ => const SizedBox.shrink(),
    },
  );
}

// Wrapper widget for consistent step styling
class _StepWrapper extends StatelessWidget {
  const _StepWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
  }
}
```

#### Step 3.3: Update Step 1 - Name and Strength
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Replace `TextFormField` with `HydraTextFormField`
- Update styling to use `AppTextStyles` and `AppSpacing`
- Keep existing validation logic
- Replace hardcoded strings with localized versions

**Code Structure**:
```dart
Widget _buildNameAndStrengthStep() {
  final l10n = context.l10n;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.medicationInformation,
        style: AppTextStyles.h2,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.medicationInformationDesc,
        style: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      // Medication Name Field
      HydraTextFormField(
        controller: _nameController,
        decoration: InputDecoration(
          labelText: l10n.medicationNameLabel,
          hintText: l10n.medicationNameHint,
          prefixIcon: HydraIcon(icon: AppIcons.medication),
        ),
        textCapitalization: TextCapitalization.words,
        onChanged: (value) {
          setState(() {
            _medicationName = value.trim();
            _hasUnsavedChanges = true;
          });
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.medicationNameRequired;
          }
          return null;
        },
      ),
      const SizedBox(height: AppSpacing.lg),

      // Strength Section
      Text(
        l10n.medicationStrengthOptional,
        style: AppTextStyles.h3,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        l10n.medicationStrengthDesc,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: HydraTextFormField(
              controller: _strengthAmountController,
              decoration: InputDecoration(
                labelText: l10n.amount,
                hintText: l10n.strengthAmountHint,
                helperText: l10n.strengthAmountHelper,
                prefixIcon: HydraIcon(icon: AppIcons.medicalInformation),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9./,]')),
              ],
              onChanged: (value) {
                setState(() {
                  _strengthAmount = value.trim();
                  _hasUnsavedChanges = true;
                });
              },
            ),
          ),
          const SizedBox(width: AppSpacing.mdSm),
          Expanded(
            flex: 2,
            child: HydraDropdown<MedicationStrengthUnit>(
              value: _strengthUnit,
              items: MedicationStrengthUnit.values,
              onChanged: _strengthAmount.isNotEmpty
                  ? (value) {
                      setState(() {
                        _strengthUnit = value;
                        _hasUnsavedChanges = true;
                      });
                    }
                  : null,
              itemBuilder: (unit) => Text(
                unit.displayName,
                overflow: TextOverflow.ellipsis,
              ),
              labelText: l10n.unit,
            ),
          ),
        ],
      ),

      // Custom unit field (if "Other" selected)
      if (_strengthUnit == MedicationStrengthUnit.other) ...[
        const SizedBox(height: AppSpacing.md),
        HydraTextFormField(
          controller: _customStrengthUnitController,
          decoration: InputDecoration(
            labelText: l10n.customUnit,
            hintText: l10n.customUnitHint,
            prefixIcon: HydraIcon(icon: AppIcons.edit),
          ),
          onChanged: (value) {
            setState(() {
              _customStrengthUnit = value.trim();
              _hasUnsavedChanges = true;
            });
          },
        ),
      ],
    ],
  );
}
```

**Required Localizations** (add to `app_en.arb`):
```json
"medicationNameRequired": "Medication name is required",
"medicationStrengthOptional": "Medication Strength (optional)",
"medicationStrengthDesc": "Enter the concentration or strength of the medication",
"amount": "Amount",
"strengthAmountHint": "e.g., 2.5, 1/2, 10",
"strengthAmountHelper": "e.g., 2.5 mg, 5 mg/mL",
"unit": "Unit",
"customUnit": "Custom Unit",
"customUnitHint": "e.g., mg/kg"
```

#### Step 3.4: Update Step 2 - Dosage and Unit
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Replace `TextFormField` with `HydraTextFormField`
- Update styling and localization
- Keep existing dosage validation logic from `DosageUtils`

**Code Structure**:
```dart
Widget _buildDosageStep() {
  final l10n = context.l10n;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l10n.dosage, style: AppTextStyles.h2),
      const SizedBox(height: AppSpacing.sm),

      RichText(
        text: TextSpan(
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(text: l10n.dosageDescriptionPart1),
            TextSpan(
              text: l10n.dosageDescriptionPart2,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: l10n.dosageDescriptionPart3),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: HydraTextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: l10n.dosageRequired,
                hintText: l10n.dosageHint,
                prefixIcon: HydraIcon(icon: AppIcons.medication),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[0-9./,]')),
              ],
              onChanged: (value) {
                setState(() {
                  _dosage = value.trim();
                  _hasUnsavedChanges = true;

                  // Validate dosage
                  final error = DosageUtils.validateDosageString(_dosage);
                  if (error != null) {
                    _dosageError = error;
                    _dosageValue = null;
                  } else {
                    _dosageError = null;
                    _dosageValue = DosageUtils.parseDosageString(_dosage);
                  }
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.dosageRequired;
                }
                return DosageUtils.validateDosageString(value.trim());
              },
            ),
          ),
          const SizedBox(width: AppSpacing.mdSm),
          Expanded(
            flex: 2,
            child: HydraDropdown<MedicationUnit>(
              value: _selectedUnit,
              items: MedicationUnit.values,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedUnit = value;
                    _hasUnsavedChanges = true;
                  });
                }
              },
              itemBuilder: (unit) => Text(
                unit.displayName,
                overflow: TextOverflow.ellipsis,
              ),
              labelText: l10n.unitRequired,
            ),
          ),
        ],
      ),
    ],
  );
}
```

**Required Localizations**:
```json
"dosage": "Dosage",
"dosageDescriptionPart1": "Enter the ",
"dosageDescriptionPart2": "amount per administration",
"dosageDescriptionPart3": " and select the medication unit.",
"dosageRequired": "Dosage *",
"dosageHint": "e.g., 1, 1/2, 2.5",
"unitRequired": "Unit *"
```

#### Step 3.5: Steps 3 & 4 - Keep Existing Widgets
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Copy `_buildFrequencyStep()` from existing implementation
- Copy `_buildReminderTimesStep()` from existing implementation
- Update text styles to use `AppTextStyles`
- Update spacing to use `AppSpacing`
- Replace hardcoded strings with localization keys

**Note**: These steps already use custom widgets (`RotatingWheelPicker`, `TimePickerGroup`) that don't need Hydra replacements.

---

### Phase 4: Implement Navigation Logic and Validation

**Goal**: Add step navigation with validation, button state management, and loading states.

#### Step 4.1: Implement Step Validation
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_validateCurrentStep()` method
- Implement step-specific validation rules
- Return validation error message or null
- Show validation errors in real-time after first attempt

**Code Structure**:
```dart
String? _validateCurrentStep() {
  final l10n = context.l10n;

  return switch (_currentStep) {
    0 => _validateStepOne(l10n),
    1 => _validateStepTwo(l10n),
    2 => _validateStepThree(l10n),
    3 => _validateStepFour(l10n),
    _ => null,
  };
}

String? _validateStepOne(AppLocalizations l10n) {
  if (_medicationName.trim().isEmpty) {
    return l10n.medicationNameRequired;
  }

  // If strength amount is provided, unit must be selected
  if (_strengthAmount.isNotEmpty && _strengthUnit == null) {
    return l10n.strengthUnitRequired;
  }

  // If "Other" unit selected, custom unit must be provided
  if (_strengthUnit == MedicationStrengthUnit.other &&
      _customStrengthUnit.trim().isEmpty) {
    return l10n.customStrengthUnitRequired;
  }

  return null;
}

String? _validateStepTwo(AppLocalizations l10n) {
  if (_dosage.trim().isEmpty) {
    return l10n.dosageRequired;
  }

  final error = DosageUtils.validateDosageString(_dosage);
  if (error != null) {
    return error;
  }

  return null;
}

String? _validateStepThree(AppLocalizations l10n) {
  // Frequency is always valid (pre-selected via picker)
  return null;
}

String? _validateStepFour(AppLocalizations l10n) {
  final expectedCount = _selectedFrequency.administrationsPerDay;
  if (_reminderTimes.length != expectedCount) {
    return l10n.reminderTimesIncomplete(expectedCount);
  }

  return null;
}
```

**Required Localizations**:
```json
"strengthUnitRequired": "Please select a strength unit",
"customStrengthUnitRequired": "Please specify the custom unit",
"reminderTimesIncomplete": "Please set all {count} reminder times"
```

#### Step 4.2: Implement Navigation Methods
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_goToNextStep()` method with validation
- Create `_goToPreviousStep()` method
- Disable buttons during animation
- Update `_hasUnsavedChanges` flag

**Code Structure**:
```dart
Future<void> _goToNextStep() async {
  // Prevent double-tap
  if (_isAnimating) return;

  // Validate current step
  final error = _validateCurrentStep();
  if (error != null) {
    // Show error snackbar
    HydraSnackBar.showError(context, error);
    return;
  }

  setState(() => _isAnimating = true);

  try {
    await _pageController.animateToPage(
      _currentStep + 1,
      duration: AppAnimations.pageSlideDuration,
      curve: AppAnimations.pageSlideCurve,
    );
  } finally {
    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }
}

Future<void> _goToPreviousStep() async {
  // Prevent double-tap
  if (_isAnimating) return;

  setState(() => _isAnimating = true);

  try {
    await _pageController.animateToPage(
      _currentStep - 1,
      duration: AppAnimations.pageSlideDuration,
      curve: AppAnimations.pageSlideCurve,
    );
  } finally {
    if (mounted) {
      setState(() => _isAnimating = false);
    }
  }
}

bool _isCurrentStepValid() {
  return _validateCurrentStep() == null;
}
```

#### Step 4.3: Implement Save Logic
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_handleSave()` method
- Show loading state during save
- Create `MedicationData` from form values
- Return via `Navigator.pop()`
- Handle errors with snackbar

**Code Structure**:
```dart
Future<void> _handleSave() async {
  if (_isAnimating || _isLoading) return;

  // Final validation
  final error = _validateCurrentStep();
  if (error != null) {
    HydraSnackBar.showError(context, error);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Convert TimeOfDay to DateTime
    final now = DateTime.now();
    final reminderDateTimes = _reminderTimes.map((time) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }).toList();

    final medication = MedicationData(
      name: _medicationName,
      unit: _selectedUnit,
      frequency: _selectedFrequency,
      reminderTimes: reminderDateTimes,
      dosage: _dosageValue,
      strengthAmount: _strengthAmount.isEmpty ? null : _strengthAmount,
      strengthUnit: _strengthUnit,
      customStrengthUnit: _customStrengthUnit.isEmpty
          ? null
          : _customStrengthUnit,
    );

    // Return medication data
    if (mounted) {
      Navigator.of(context).pop(medication);
    }
  } on Exception catch (e) {
    if (mounted) {
      HydraSnackBar.showError(
        context,
        context.l10n.errorSavingMedication,
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
```

**Required Localization**:
```json
"errorSavingMedication": "Failed to save medication. Please check all fields and try again."
```

#### Step 4.4: Implement Footer with Navigation Buttons
**File**: `lib/features/onboarding/screens/add_medication_bottom_sheet.dart`

**Tasks**:
- Create `_buildFooter()` method
- Show Previous button only when not on first step
- Show Next button on steps 1-3, Save button on step 4
- Disable buttons during animation or loading
- Apply proper styling with `HydraButton`

**Code Structure**:
```dart
Widget _buildFooter(BuildContext context) {
  final l10n = context.l10n;
  final isFirstStep = _currentStep == 0;
  final isLastStep = _currentStep == _totalSteps - 1;
  final isNextEnabled = _isCurrentStepValid() && !_isAnimating && !_isLoading;

  return Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(
        top: BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: Row(
        children: [
          // Previous button
          if (!isFirstStep)
            Expanded(
              child: HydraButton(
                onPressed: _isAnimating || _isLoading
                    ? null
                    : _goToPreviousStep,
                variant: HydraButtonVariant.secondary,
                child: Text(l10n.previous),
              ),
            ),

          if (!isFirstStep)
            const SizedBox(width: AppSpacing.md),

          // Next/Save button
          Expanded(
            child: HydraButton(
              onPressed: isNextEnabled
                  ? (isLastStep ? _handleSave : _goToNextStep)
                  : null,
              variant: HydraButtonVariant.primary,
              isLoading: _isLoading,
              child: Text(isLastStep ? l10n.save : l10n.next),
            ),
          ),
        ],
      ),
    ),
  );
}
```

**Required Localizations**:
```json
"previous": "Previous",
"next": "Next",
"save": "Save"
```

---

### Phase 5: Integration and Cleanup

**Goal**: Replace old implementation with new bottom sheet and clean up deprecated code.

#### Step 5.1: Update Callers to Use New Bottom Sheet
**Files to Update**:
- `lib/features/onboarding/screens/*` (wherever `AddMedicationScreen` is called)
- Any profile/settings screens that allow editing medications

**Tasks**:
- Replace `showDialog` + `AddMedicationScreen` with `showAddMedicationBottomSheet`
- Update imports
- Test that medication data is properly returned and saved

**Example Update**:
```dart
// BEFORE
final medication = await showDialog<MedicationData>(
  context: context,
  builder: (context) => AddMedicationScreen(
    initialMedication: existing,
    isEditing: true,
  ),
);

// AFTER
final medication = await showAddMedicationBottomSheet(
  context: context,
  initialMedication: existing,
  isEditing: true,
);
```

#### Step 5.2: Remove Deprecated Files
**Files to Remove**:
- `lib/features/onboarding/screens/add_medication_screen.dart` (old dialog version)
- `lib/features/onboarding/widgets/treatment_popup_wrapper.dart` (if no longer used elsewhere)
- `lib/features/onboarding/widgets/medication_overlay_wrapper.dart` (if it exists and is unused)

**Tasks**:
- Verify files are no longer imported anywhere
- Delete deprecated files
- Run `flutter analyze` to check for broken imports

#### Step 5.3: Update Exports
**File**: `lib/shared/widgets/widgets.dart` or relevant export file

**Tasks**:
- Add export for `showAddMedicationBottomSheet`
- Remove exports for deleted widgets

**Code**:
```dart
// Add to widgets.dart or create onboarding exports file
export 'package:hydracat/features/onboarding/screens/add_medication_bottom_sheet.dart';
export 'package:hydracat/features/onboarding/widgets/medication_step_progress_indicator.dart';
```

---

### Phase 6: Testing and Polish

**Goal**: Test the complete flow, fix any issues, and ensure accessibility.

#### Step 6.1: Manual Testing Checklist

**Flow Testing**:
- [ ] Open add medication flow from onboarding
- [ ] Navigate forward through all 4 steps
- [ ] Navigate backward through steps
- [ ] Test validation on each step (try advancing with invalid data)
- [ ] Test unsaved changes warning (close without saving)
- [ ] Complete full flow and verify medication is saved
- [ ] Edit existing medication and verify changes persist
- [ ] Test keyboard handling (inputs visible when keyboard shows)

**Animation Testing**:
- [ ] Verify smooth slide transitions between steps
- [ ] Check progress indicator animations (circles, lines, checkmarks)
- [ ] Verify active step pulse animation
- [ ] Test with reduced motion enabled (animations should be disabled)

**Platform Testing**:
- [ ] Test on iOS (Cupertino styling)
- [ ] Test on Android (Material styling)
- [ ] Verify HydraIcon shows correct platform icons

**Edge Cases**:
- [ ] Test with very long medication names
- [ ] Test with fractional dosages (1/2, 3/4, etc.)
- [ ] Test custom strength units
- [ ] Test all frequency options (once daily, every 3 days, etc.)
- [ ] Test with maximum reminder times (3x daily)

#### Step 6.2: Accessibility Testing
**Tasks**:
- Test with VoiceOver (iOS) / TalkBack (Android)
- Verify all buttons have semantic labels
- Verify touch targets are 44x44 minimum
- Test keyboard navigation (tab order)
- Test with large text sizes
- Test with reduced motion preference

#### Step 6.3: Run Flutter Analyze
**Command**: `flutter analyze`

**Tasks**:
- Fix all analyzer warnings and errors
- Address any deprecated API usage
- Ensure no unused imports
- Fix any formatting issues

#### Step 6.4: Performance Check
**Tasks**:
- Check for dropped frames during animations
- Verify memory usage is stable
- Test with Flutter DevTools performance overlay
- Ensure animations run at 60fps

---

## Summary of Key Changes

### Architecture Improvements
1. **Bottom Sheet Presentation**: Modern, mobile-first UI pattern
2. **Component Standardization**: All inputs use Hydra components
3. **Animation System**: Smooth, configurable transitions with accessibility support
4. **Validation Strategy**: Progressive validation with helpful feedback
5. **State Management**: Clear separation of concerns, proper state tracking

### User Experience Enhancements
1. **Visual Feedback**: Animated progress indicator shows current position
2. **Smooth Transitions**: Elegant slide animations between steps
3. **Safety Features**: Unsaved changes warning prevents data loss
4. **Better Keyboard Handling**: Content scrolls properly, inputs remain accessible
5. **Disabled State Clarity**: Users can't navigate with invalid data

### Code Quality Improvements
1. **Reusable Components**: Progress indicator can be used elsewhere
2. **Consistent Styling**: Uses design system constants throughout
3. **Localized Text**: All user-facing strings are localized
4. **Platform Adaptive**: Proper Material/Cupertino adaptation
5. **Testable**: Clear state management, separated concerns

### Accessibility Wins
1. **Reduce Motion Support**: Animations respect system preferences
2. **Semantic Labels**: All interactive elements properly labeled
3. **Touch Targets**: Meet WCAG 2.1 AA standards (44x44 minimum)
4. **Keyboard Navigation**: Proper focus management and tab order
5. **Screen Reader Support**: VoiceOver/TalkBack friendly

---

## Post-Implementation Notes

### Files Created
- `lib/features/onboarding/screens/add_medication_bottom_sheet.dart` (350+ lines)
- `lib/features/onboarding/widgets/medication_step_progress_indicator.dart` (200+ lines)

### Files Modified
- `lib/l10n/app_en.arb` (added ~25 localization keys)
- Caller files (screens that invoke medication flow)
- Widget exports file

### Files Deleted
- `lib/features/onboarding/screens/add_medication_screen.dart`
- `lib/features/onboarding/widgets/treatment_popup_wrapper.dart` (if not used elsewhere)

### Testing Required
- Manual flow testing on both iOS and Android
- Accessibility testing with screen readers
- Performance validation (animations at 60fps)
- Edge case validation (long names, fractional dosages, etc.)

### Future Enhancements (Out of Scope)
- Medication photo upload
- Barcode scanning for medication lookup
- Medication interaction warnings
- Multi-medication batch entry
- Medication history/archive view

---

## Alignment with Best Practices

### Flutter Best Practices ✅
- **Widget Composition**: Small, focused, reusable widgets
- **State Management**: Proper use of StatefulWidget, controlled by parent
- **Performance**: ListView.builder not needed (fixed 4 items), const constructors where possible
- **Platform Adaptation**: Uses Hydra components for automatic adaptation

### Material Design / iOS Guidelines ✅
- **Bottom Sheets**: Follows Material 3 and iOS modal presentation patterns
- **Animations**: Smooth, purposeful, with proper timing (200-300ms sweet spot)
- **Touch Targets**: 44x44 minimum, proper spacing
- **Typography**: Uses semantic text styles, proper hierarchy

### Accessibility Standards (WCAG 2.1 AA) ✅
- **Color Contrast**: 4.5:1 minimum for all text
- **Touch Targets**: 44x44 minimum
- **Keyboard Navigation**: Full keyboard support
- **Screen Readers**: Semantic labels, proper announcements
- **Reduce Motion**: Animations disabled when requested

### HydraCat Design System ✅
- **Consistent Components**: Uses all Hydra widgets
- **Design Tokens**: AppColors, AppSpacing, AppTextStyles, AppBorderRadius
- **Animation Constants**: AppAnimations for durations and curves
- **Icon System**: HydraIcon with platform-specific icons

### Firebase Best Practices ✅
- **No Additional Reads**: Uses existing data, no Firestore queries
- **Offline-First**: Works completely offline until save
- **Optimistic UI**: Immediate feedback, syncs asynchronously

---

## Conclusion

This refactor transforms the medication flow from a basic dialog into a polished, modern, mobile-first experience that aligns with HydraCat's design system and industry standards. The implementation is:

- **Production-Ready**: Follows all best practices, fully localized, accessible
- **Maintainable**: Clear architecture, reusable components, well-documented
- **Extensible**: Easy to add more steps or modify validation logic
- **Performant**: Smooth 60fps animations, minimal overhead
- **User-Friendly**: Progressive validation, helpful feedback, safety features

The phased approach allows for incremental implementation and testing, reducing risk and ensuring quality at each step.
