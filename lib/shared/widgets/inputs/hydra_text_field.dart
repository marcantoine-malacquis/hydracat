import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform-adaptive text field for HydraCat.
///
/// Wraps [TextField] on Material platforms and [CupertinoTextField] on iOS/macOS,
/// while mirroring the core [TextField] API used in the app.
///
/// **API Differences:**
/// - Material: Full [InputDecoration] support including `errorText`, `counter`,
///  etc.
/// - Cupertino: `placeholder` from `decoration?.hintText`, `prefix`/`suffix` from
///   `decoration?.prefixIcon`/`suffixIcon` or `suffixText`. Error text and counter
///   are shown separately below the field on iOS.
class HydraTextField extends StatelessWidget {
  /// Creates a platform-adaptive text field.
  const HydraTextField({
    this.controller,
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.textDirection,
    this.readOnly = false,
    this.showCursor,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onAppPrivateCommand,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20),
    this.dragStartBehavior = DragStartBehavior.start,
    this.mouseCursor,
    this.buildCounter,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.clipBehavior = Clip.hardEdge,
    this.restorationId,
    this.undoController,
    this.onTap,
    this.onTapOutside,
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    super.key,
  });

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Decoration for the text field (Material only).
  ///
  /// On iOS, `hintText` maps to `placeholder`, `prefixIcon`/`suffixIcon` map to
  /// `prefix`/`suffix`, and `suffixText` maps to a text suffix widget.
  final InputDecoration? decoration;

  /// Type of keyboard to display.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Capitalization mode for text input.
  final TextCapitalization textCapitalization;

  /// Style for the text being edited.
  final TextStyle? style;

  /// How the text should be aligned horizontally.
  final TextAlign textAlign;

  /// How the text should be aligned vertically.
  final TextAlignVertical? textAlignVertical;

  /// Directionality of the text.
  final TextDirection? textDirection;

  /// Whether the text field is read-only.
  final bool readOnly;

  /// Whether to show the cursor.
  final bool? showCursor;

  /// Whether this text field should be focused initially.
  final bool autofocus;

  /// Whether to hide the text being edited.
  final bool obscureText;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Type of smart dashes to apply.
  final SmartDashesType? smartDashesType;

  /// Type of smart quotes to apply.
  final SmartQuotesType? smartQuotesType;

  /// Whether to enable suggestions.
  final bool enableSuggestions;

  /// Maximum number of lines for the text field.
  final int? maxLines;

  /// Minimum number of lines for the text field.
  final int? minLines;

  /// Whether the text field expands to fill available vertical space.
  final bool expands;

  /// Maximum length of the text.
  final int? maxLength;

  /// Enforcement mode for maxLength.
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// Called when the text being edited changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the text field.
  final VoidCallback? onEditingComplete;

  /// Called when the user indicates they are done editing the text field.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user requests a private command.
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// Input formatters for the text field.
  final List<TextInputFormatter>? inputFormatters;

  /// Whether the text field is enabled.
  final bool? enabled;

  /// Width of the cursor.
  final double cursorWidth;

  /// Height of the cursor.
  final double? cursorHeight;

  /// Radius of the cursor.
  final Radius? cursorRadius;

  /// Color of the cursor.
  final Color? cursorColor;

  /// Appearance of the keyboard.
  final Brightness? keyboardAppearance;

  /// Padding around the text field when scrolling into view.
  final EdgeInsets scrollPadding;

  /// Behavior when starting to drag.
  final DragStartBehavior dragStartBehavior;

  /// Mouse cursor for the text field.
  final MouseCursor? mouseCursor;

  /// Builder for the character counter.
  final InputCounterWidgetBuilder? buildCounter;

  /// Controller for the scroll view.
  final ScrollController? scrollController;

  /// Physics for the scroll view.
  final ScrollPhysics? scrollPhysics;

  /// Autofill hints for the text field.
  final Iterable<String>? autofillHints;

  /// Clip behavior for the text field.
  final Clip clipBehavior;

  /// Restoration ID for the text field.
  final String? restorationId;

  /// Controller for undo/redo operations.
  final UndoHistoryController? undoController;

  /// Called when the text field is tapped.
  final GestureTapCallback? onTap;

  /// Called when a tap occurs outside the text field.
  final TapRegionCallback? onTapOutside;

  /// Builder for the context menu.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Whether the text field can request focus.
  final bool canRequestFocus;

  /// Configuration for spell checking.
  final SpellCheckConfiguration? spellCheckConfiguration;

  /// Configuration for the magnifier.
  final TextMagnifierConfiguration? magnifierConfiguration;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return _buildCupertinoTextField(context);
    }

    return _buildMaterialTextField(context);
  }

  Widget _buildMaterialTextField(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      textDirection: textDirection,
      readOnly: readOnly,
      showCursor: showCursor,
      autofocus: autofocus,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      onAppPrivateCommand: onAppPrivateCommand,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      dragStartBehavior: dragStartBehavior,
      mouseCursor: mouseCursor,
      buildCounter: buildCounter,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      clipBehavior: clipBehavior,
      restorationId: restorationId,
      undoController: undoController,
      onTap: onTap,
      onTapOutside: onTapOutside,
      contextMenuBuilder: contextMenuBuilder,
      canRequestFocus: canRequestFocus,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
    );
  }

  Widget _buildCupertinoTextField(BuildContext context) {
    final decoration = this.decoration;
    final theme = CupertinoTheme.of(context);

    // Extract placeholder from decoration hintText
    final placeholder = decoration?.hintText;

    // Extract prefix/suffix from decoration
    Widget? prefix;
    Widget? suffix;

    if (decoration != null) {
      // Map prefixIcon to prefix
      if (decoration.prefixIcon != null) {
        prefix = decoration.prefixIcon;
      }

      // Map suffixIcon to suffix (preferred over suffixText)
      if (decoration.suffixIcon != null) {
        suffix = decoration.suffixIcon;
      } else if (decoration.suffixText != null) {
        // Map suffixText to a text suffix widget
        suffix = Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Text(
            decoration.suffixText!,
            style:
                style?.copyWith(
                  color: theme.textTheme.textStyle.color?.withValues(
                    alpha: 0.6,
                  ),
                ) ??
                theme.textTheme.textStyle.copyWith(
                  color: theme.textTheme.textStyle.color?.withValues(
                    alpha: 0.6,
                  ),
                ),
          ),
        );
      }
    }

    // Extract padding from decoration contentPadding
    final contentPadding = decoration?.contentPadding;
    final padding = contentPadding ?? EdgeInsets.zero;

    // Build the CupertinoTextField
    final cupertinoField = CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      placeholder: placeholder,
      prefix: prefix,
      suffix: suffix,
      padding: padding,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      style: style,
      textAlign: textAlign,
      readOnly: readOnly,
      autofocus: autofocus,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      maxLengthEnforcement: maxLengthEnforcement,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      onTap: onTap,
      inputFormatters: inputFormatters,
      enabled: enabled ?? true,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      dragStartBehavior: dragStartBehavior,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      restorationId: restorationId,
      undoController: undoController,
      contextMenuBuilder: contextMenuBuilder,
      spellCheckConfiguration: spellCheckConfiguration,
      magnifierConfiguration: magnifierConfiguration,
    );

    // Wrap with error text and counter if needed (CupertinoTextField doesn't
    // support these in decoration)
    final errorText = decoration?.errorText;
    final counter = decoration?.counter;
    final hasError = errorText != null && errorText.isNotEmpty;
    final hasCounter = counter != null;

    if (hasError || hasCounter) {
      // Extract non-null values when we know they're safe
      String? errorTextValue;
      Widget? counterValue;
      if (hasError) {
        errorTextValue = errorText;
      }
      if (hasCounter) {
        counterValue = counter;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          cupertinoField,
          if (hasError && errorTextValue != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                errorTextValue,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          if (hasCounter && !hasError && counterValue != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DefaultTextStyle(
                style: TextStyle(
                  color:
                      theme.textTheme.textStyle.color?.withValues(alpha: 0.6) ??
                      CupertinoColors.placeholderText,
                  fontSize: 12,
                ),
                child: counterValue,
              ),
            ),
          ],
        ],
      );
    }

    return cupertinoField;
  }

  /// Default context menu builder for Material platforms.
  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }
}
