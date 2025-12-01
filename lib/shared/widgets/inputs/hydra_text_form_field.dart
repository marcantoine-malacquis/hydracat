import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydracat/shared/widgets/inputs/hydra_text_field.dart';

/// Platform-adaptive text form field for HydraCat.
///
/// Wraps [HydraTextField] with [FormField] to support form validation.
/// Maintains the same API as [TextFormField] for easy migration.
class HydraTextFormField extends FormField<String> {
  /// Creates a platform-adaptive text form field.
  HydraTextFormField({
    super.key,
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
    this.isEnabled,
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
    super.restorationId,
    this.undoController,
    this.onTap,
    this.onTapOutside,
    this.contextMenuBuilder,
    this.canRequestFocus = true,
    this.spellCheckConfiguration,
    this.magnifierConfiguration,
    super.validator,
    String? initialValue,
    bool autovalidateMode = false,
    super.onSaved,
  }) : super(
         initialValue: controller?.text ?? initialValue ?? '',
         autovalidateMode: autovalidateMode
             ? AutovalidateMode.always
             : AutovalidateMode.disabled,
         builder: (FormFieldState<String> field) {
           final state = field as _HydraTextFormFieldState;
           final hasError = field.hasError;
           final errorText = hasError ? field.errorText : null;

           // Merge error text into decoration
           final effectiveDecoration = (decoration ?? const InputDecoration())
               .copyWith(errorText: errorText);

           return HydraTextField(
             controller: state._effectiveController,
             focusNode: focusNode,
             decoration: effectiveDecoration,
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
             onChanged: (value) {
               field.didChange(value);
               onChanged?.call(value);
             },
             onEditingComplete: onEditingComplete,
             onSubmitted: onSubmitted,
             onAppPrivateCommand: onAppPrivateCommand,
             inputFormatters: inputFormatters,
             enabled: isEnabled,
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
             restorationId: field.widget.restorationId,
             undoController: undoController,
             onTap: onTap,
             onTapOutside: onTapOutside,
             contextMenuBuilder: contextMenuBuilder,
             canRequestFocus: canRequestFocus,
             spellCheckConfiguration: spellCheckConfiguration,
             magnifierConfiguration: magnifierConfiguration,
           );
         },
       );

  /// Controller for the text field.
  final TextEditingController? controller;

  /// Focus node for the text field.
  final FocusNode? focusNode;

  /// Decoration for the text field.
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
  final bool? isEnabled;

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

  /// Configuration for the text magnifier.
  final TextMagnifierConfiguration? magnifierConfiguration;

  @override
  FormFieldState<String> createState() => _HydraTextFormFieldState();
}

class _HydraTextFormFieldState extends FormFieldState<String> {
  TextEditingController? _controller;
  TextEditingController? _effectiveController;

  @override
  void initState() {
    super.initState();
    final widget = this.widget as HydraTextFormField;

    // Use provided controller or create one from initialValue
    if (widget.controller != null) {
      _effectiveController = widget.controller;
    } else {
      _controller = TextEditingController(text: widget.initialValue ?? '');
      _effectiveController = _controller;

      // Listen to controller changes to sync with FormField state
      _controller!.addListener(() {
        if (value != _controller!.text) {
          didChange(_controller!.text);
        }
      });
    }
  }

  @override
  void didChange(String? value) {
    super.didChange(value);
    // Update controller if we own it
    if (_controller != null && _controller!.text != value) {
      _controller!.text = value ?? '';
    }
  }

  @override
  void reset() {
    super.reset();
    if (_controller != null) {
      _controller!.text = widget.initialValue ?? '';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
