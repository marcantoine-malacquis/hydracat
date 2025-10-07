import 'package:flutter/material.dart';
import 'package:hydracat/core/theme/app_spacing.dart';
import 'package:hydracat/features/onboarding/models/treatment_data.dart';

/// A custom dropdown selector for fluid injection sites.
///
/// Provides a dropdown menu with all FluidLocation enum values.
/// Used in fluid logging to specify where the treatment was administered.
///
/// Features:
/// - All FluidLocation enum options
/// - User-friendly display names
/// - Pre-filled from schedule's preferredLocation
/// - Defaults to shoulderBladeLeft when no schedule
/// - Matches TextField styling for consistency
/// - Custom dropdown that works within overlay popups
///
/// Example:
/// ```dart
/// InjectionSiteSelector(
///   value: _selectedInjectionSite,
///   onChanged: (FluidLocation? newValue) {
///     setState(() {
///       _selectedInjectionSite = newValue;
///     });
///   },
/// )
/// ```
class InjectionSiteSelector extends StatefulWidget {
  /// Creates an [InjectionSiteSelector].
  const InjectionSiteSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// Currently selected injection site
  final FluidLocation? value;

  /// Callback when selection changes
  final ValueChanged<FluidLocation?> onChanged;

  /// Whether the selector is enabled
  final bool enabled;

  @override
  State<InjectionSiteSelector> createState() => _InjectionSiteSelectorState();
}

class _InjectionSiteSelectorState extends State<InjectionSiteSelector> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
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
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: FluidLocation.values.map((location) {
                        final isSelected = widget.value == location;
                        return InkWell(
                          onTap: () {
                            widget.onChanged(location);
                            _removeOverlay();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                if (isSelected)
                                  const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    location.displayName,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
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
        label: 'Injection site selector',
        hint: widget.value != null
            ? 'Current selection: ${widget.value!.displayName}'
            : 'No injection site selected',
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? _toggleDropdown : null,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Injection Site',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                suffixIcon: Icon(
                  _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: widget.enabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
              child: Text(
                widget.value?.displayName ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: widget.value != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
