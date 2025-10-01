# Touch Target Accessibility Guidelines

This document provides guidelines for ensuring all interactive elements in HydraCat meet minimum touch target size requirements for accessibility.

## 📏 Touch Target Standards

### Minimum Size Requirements
- **Minimum touch target**: 44×44px (Apple HIG & Material Design)
- **FAB buttons**: 56×56px
- **Source**: `AppAccessibility.minTouchTarget` and `AppAccessibility.fabTouchTarget`

### Why Touch Target Size Matters
1. **Accessibility**: Users with motor impairments need larger targets
2. **Usability**: Reduces tap errors and improves user experience
3. **Mobile-first**: Essential for touch-based interfaces
4. **Standards compliance**: Meets WCAG 2.1 Level AAA guidelines

---

## 🛠 Available Components

### 1. `HydraTouchTarget`
**Purpose**: Wraps any widget to ensure minimum touch target size

**When to use**:
- Custom `GestureDetector` or `InkWell` implementations
- Small interactive widgets (< 44×44px content)
- Selection cards with minimal padding
- Toggle buttons without sufficient size

**Example**:
```dart
HydraTouchTarget(
  semanticLabel: 'Select medication',
  child: GestureDetector(
    onTap: () => selectMedication(),
    child: Container(
      padding: EdgeInsets.all(8),
      child: Icon(Icons.medication, size: 20),
    ),
  ),
)
```

**Parameters**:
- `child` (required): The widget to wrap
- `minSize`: Minimum size (defaults to 44px)
- `alignment`: Child alignment within touch target
- `semanticLabel`: Label for screen readers
- `excludeSemantics`: Exclude child's semantics

---

### 2. `TouchTargetIconButton`
**Purpose**: IconButton wrapper with guaranteed touch target compliance

**When to use**:
- All IconButton instances with custom sizes
- Icon-only action buttons
- Toolbar buttons
- Card action buttons (edit, delete, etc.)

**Example**:
```dart
TouchTargetIconButton(
  icon: Icon(Icons.edit, size: 20),
  onPressed: () => editItem(),
  tooltip: 'Edit item',
  semanticLabel: 'Edit medication details',
)
```

**Parameters**:
- `icon` (required): Icon widget
- `onPressed` (required): Tap callback
- `tooltip`: Tooltip text
- `semanticLabel`: Screen reader label (defaults to tooltip)
- `color`: Icon color
- `iconSize`: Icon size (doesn't affect touch target)
- `visualDensity`: Visual density (touch target maintained)
- `padding`: Internal padding
- `splashRadius`: Ripple effect radius

---

## ✅ When to Use Touch Target Components

### **Required**:
1. ✅ Custom `GestureDetector` with content < 44×44px
2. ✅ `IconButton` with `iconSize` < 24px
3. ✅ Toggle buttons (radio, checkbox alternatives)
4. ✅ Selection cards with icon-only content
5. ✅ Custom time/date pickers
6. ✅ Compact UI controls

### **Not Required**:
1. ❌ `ElevatedButton` (already 48px min height)
2. ❌ `TextButton` with sufficient text
3. ❌ `FloatingActionButton` (already 56×56px)
4. ❌ Large interactive cards (> 44×44px)
5. ❌ Non-interactive decorative elements
6. ❌ List tiles with sufficient height

---

## 🎯 Implementation Patterns

### Pattern 1: Custom Time Picker
```dart
// GOOD ✅
HydraTouchTarget(
  semanticLabel: 'Select time',
  child: GestureDetector(
    onTap: () => showTimePicker(context),
    child: Container(
      constraints: BoxConstraints(
        minHeight: AppAccessibility.minTouchTarget,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: 20),
          SizedBox(width: 8),
          Text(time.format(context)),
        ],
      ),
    ),
  ),
)

// BAD ❌
GestureDetector(
  onTap: () => showTimePicker(context),
  child: Container(
    padding: EdgeInsets.all(8), // Only 24px total
    child: Icon(Icons.access_time, size: 20),
  ),
)
```

### Pattern 2: Action Buttons in Cards
```dart
// GOOD ✅
TouchTargetIconButton(
  icon: Icon(Icons.delete, size: 20),
  onPressed: () => deleteItem(),
  tooltip: 'Delete item',
  semanticLabel: 'Delete medication',
)

// BAD ❌
IconButton(
  icon: Icon(Icons.delete, size: 20),
  onPressed: () => deleteItem(),
  // No touch target guarantee
)
```

### Pattern 3: Selection Cards
```dart
// GOOD ✅
GestureDetector(
  onTap: () => selectPersona(),
  child: Container(
    constraints: BoxConstraints(
      minWidth: AppAccessibility.minTouchTarget,
      minHeight: AppAccessibility.minTouchTarget,
    ),
    padding: EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        Icon(Icons.medication, size: 40),
        SizedBox(height: 8),
        Text('Medication Only'),
      ],
    ),
  ),
)

// ACCEPTABLE (if content guarantees size)
// But GOOD is safer for future changes
```

---

## 🧪 Testing Touch Targets

### Manual Testing
1. Run app on physical device
2. Enable "Show layout bounds" in Developer Options (Android)
3. Verify all interactive elements are tappable
4. Test with large fingers/thumbs

### Automated Testing
```dart
testWidgets('HydraTouchTarget enforces minimum size', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HydraTouchTarget(
        child: Container(width: 10, height: 10),
      ),
    ),
  );

  final box = tester.getSize(find.byType(ConstrainedBox));
  expect(box.width, greaterThanOrEqualTo(44));
  expect(box.height, greaterThanOrEqualTo(44));
});
```

### Integration Testing
```dart
testWidgets('All buttons meet touch target minimum', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();

  final buttons = find.byType(GestureDetector);
  for (var i = 0; i < buttons.evaluate().length; i++) {
    final size = tester.getSize(buttons.at(i));
    expect(size.width, greaterThanOrEqualTo(44),
        reason: 'Button $i width too small');
    expect(size.height, greaterThanOrEqualTo(44),
        reason: 'Button $i height too small');
  }
});
```

---

## 📋 Code Review Checklist

When reviewing PRs, verify:

- [ ] All custom `GestureDetector` instances wrapped in `HydraTouchTarget`
- [ ] All `IconButton` instances use `TouchTargetIconButton` or have explicit constraints
- [ ] Small interactive widgets have explicit `minHeight`/`minWidth` constraints
- [ ] Semantic labels provided for screen readers
- [ ] Touch targets tested on physical device
- [ ] No hardcoded touch target sizes (use `AppAccessibility` constants)

---

## 🔧 Migration Guide

### Migrating Existing Code

#### Before:
```dart
IconButton(
  icon: Icon(Icons.edit, size: 20),
  onPressed: () => edit(),
  tooltip: 'Edit',
)
```

#### After:
```dart
TouchTargetIconButton(
  icon: Icon(Icons.edit, size: 20),
  onPressed: () => edit(),
  tooltip: 'Edit',
  semanticLabel: 'Edit item',
)
```

### Migrating Custom Gestures

#### Before:
```dart
GestureDetector(
  onTap: () => select(),
  child: Container(
    padding: EdgeInsets.all(8),
    child: Text('Select'),
  ),
)
```

#### After:
```dart
HydraTouchTarget(
  semanticLabel: 'Select option',
  child: GestureDetector(
    onTap: () => select(),
    child: Container(
      constraints: BoxConstraints(
        minHeight: AppAccessibility.minTouchTarget,
      ),
      padding: EdgeInsets.all(8),
      child: Text('Select'),
    ),
  ),
)
```

---

## 📚 Resources

### Standards & Guidelines
- [Apple Human Interface Guidelines - Touch Targets](https://developer.apple.com/design/human-interface-guidelines/inputs/touchscreen-gestures)
- [Material Design - Touch Targets](https://material.io/design/usability/accessibility.html#layout-and-typography)
- [WCAG 2.1 - Target Size (Level AAA)](https://www.w3.org/WAI/WCAG21/Understanding/target-size.html)

### Internal References
- `lib/core/constants/app_accessibility.dart` - Accessibility constants
- `lib/shared/widgets/accessibility/hydra_touch_target.dart` - Base component
- `lib/shared/widgets/accessibility/touch_target_icon_button.dart` - IconButton wrapper

---

## 🚀 Best Practices

1. **Use components consistently**: Always use `TouchTargetIconButton` instead of raw `IconButton`
2. **Explicit over implicit**: Add explicit constraints even if content seems large enough
3. **Semantic labels**: Always provide meaningful labels for screen readers
4. **Test on devices**: Don't rely solely on emulator testing
5. **Single source of truth**: Use `AppAccessibility` constants, never hardcode sizes
6. **Document exceptions**: If you must have a smaller touch target, document why
7. **Consider context**: Back buttons in navigation bars may need special handling

---

## ❓ FAQ

### Q: Do I need to wrap ElevatedButton?
**A:** No, Flutter's `ElevatedButton` already has a minimum height of 48px.

### Q: What about ListTile?
**A:** `ListTile` has a default height of 56px, so it's compliant. However, custom list items need verification.

### Q: Can I use a smaller touch target for design reasons?
**A:** Avoid this if possible. If absolutely necessary, document the reason and ensure it's reviewed by UX/accessibility team.

### Q: How do I handle icon-only buttons in toolbars?
**A:** Use `TouchTargetIconButton` which maintains 44×44px touch target while allowing custom icon sizes.

### Q: What if my widget is already large enough?
**A:** Add explicit constraints anyway for future-proofing. Content might change, but constraints prevent regressions.

---

## 📞 Support

For questions or issues with touch target implementation:
1. Check this guide first
2. Review existing implementations in `lib/features/onboarding/widgets/`
3. Consult with UX/accessibility team
4. Raise issue in GitHub with `accessibility` label

---

**Last Updated**: 2025-10-01
**Maintained By**: HydraCat Development Team
