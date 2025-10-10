import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';

/// A custom dropdown widget that works properly in overlay contexts.
///
/// This widget uses CompositedTransformTarget and CompositedTransformFollower
/// to create a dropdown that appears above all other content, including
/// overlay backgrounds. This solves the z-index issues that occur with
/// standard DropdownButton widgets in overlay contexts.
///
/// Example:
/// ```dart
/// CustomDropdown<String>(
///   value: _selectedValue,
///   items: ['Option 1', 'Option 2', 'Option 3'],
///   onChanged: (value) => setState(() => _selectedValue = value),
///   itemBuilder: (item) => Text(item),
///   labelText: 'Select Option',
/// )
/// ```
class CustomDropdown<T> extends StatefulWidget {
  /// Creates a [CustomDropdown].
  const CustomDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemBuilder,
    this.labelText,
    this.enabled = true,
    this.hintText,
    super.key,
  });

  /// Currently selected value
  final T? value;

  /// List of available items
  final List<T> items;

  /// Callback when selection changes
  final ValueChanged<T?> onChanged;

  /// Builder for individual dropdown items
  final Widget Function(T item) itemBuilder;

  /// Label text for the dropdown
  final String? labelText;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Hint text when no value is selected
  final String? hintText;

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _removeOverlay,
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200, // ~4-5 items visible
                      minHeight: 100, // Ensure minimum usability
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView(
                        controller: _scrollController,
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: widget.items.map((item) {
                          final isSelected = widget.value == item;
                          final theme = Theme.of(context);
                          return InkWell(
                            onTap: () {
                              widget.onChanged(item);
                              _removeOverlay();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  if (isSelected)
                                    Icon(
                                      Icons.check,
                                      size: 20,
                                      color: theme.colorScheme.primary,
                                    ),
                                  if (isSelected)
                                    const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: widget.itemBuilder(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        label: widget.labelText ?? 'Dropdown selector',
        hint: widget.value != null
            ? 'Current selection: ${widget.itemBuilder(widget.value as T)}'
            : widget.hintText ?? 'No selection',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _toggleDropdown : null,
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: widget.labelText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                suffixIcon: Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: widget.enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
              child: widget.value != null
                  ? widget.itemBuilder(widget.value as T)
                  : Text(
                      widget.hintText ?? '',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
