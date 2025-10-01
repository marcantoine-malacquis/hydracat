import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A reusable iOS-style rotating wheel picker component
class RotatingWheelPicker<T> extends StatefulWidget {
  /// Creates a [RotatingWheelPicker]
  const RotatingWheelPicker({
    required this.items,
    required this.onSelectedItemChanged,
    this.initialIndex = 0,
    this.itemHeight = 32.0,
    this.diameterRatio = 1.07,
    this.useMagnifier = true,
    this.magnification = 1.0,
    super.key,
  });

  /// List of items to display in the picker
  final List<T> items;

  /// Callback when selected item changes
  final ValueChanged<int> onSelectedItemChanged;

  /// Initial selected index
  final int initialIndex;

  /// Height of each item in the picker
  final double itemHeight;

  /// Diameter ratio of the picker cylinder
  final double diameterRatio;

  /// Whether to use magnification effect
  final bool useMagnifier;

  /// Magnification factor for selected item
  final double magnification;

  @override
  State<RotatingWheelPicker<T>> createState() => _RotatingWheelPickerState<T>();
}

class _RotatingWheelPickerState<T> extends State<RotatingWheelPicker<T>> {
  late FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FixedExtentScrollController(
      initialItem: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: widget.itemHeight * 5, // Show ~5 items at once
      child: CupertinoPicker(
        scrollController: _controller,
        itemExtent: widget.itemHeight,
        diameterRatio: widget.diameterRatio,
        useMagnifier: widget.useMagnifier,
        magnification: widget.magnification,
        onSelectedItemChanged: widget.onSelectedItemChanged,
        selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
          background: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
        children: widget.items
            .map((item) => _buildPickerItem(context, item))
            .toList(),
      ),
    );
  }

  Widget _buildPickerItem(BuildContext context, T item) {
    final theme = Theme.of(context);

    String displayText;
    if (item is Enum) {
      // Handle enum types - try to get displayName property
      try {
        displayText = (item as dynamic).displayName as String;
      } on Exception {
        // Fallback to name property for simple enums
        displayText = (item as dynamic).name as String;
      }
    } else {
      displayText = item.toString();
    }

    return Center(
      child: Text(
        displayText,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
