import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Accessible Material 3 form text field with consistent decoration,
/// validation, disabled styling, focus control, and prefix/suffix support.
final class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.fieldKey,
    this.controller,
    this.focusNode,
    this.initialValue,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.maxLength,
    this.showCounter = false,
    this.textAlign = TextAlign.start,
    this.style,
    this.autovalidateMode,
  });

  final GlobalKey<FormFieldState<String>>? fieldKey;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? initialValue;
  final String label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final bool autofocus;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final int? maxLength;
  final bool showCounter;
  final TextAlign textAlign;
  final TextStyle? style;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      initialValue: initialValue,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      autofocus: autofocus,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      autocorrect: autocorrect,
      enableSuggestions: autocorrect,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      textAlign: textAlign,
      style: style,
      keyboardType: keyboardType,
      textInputAction:
          textInputAction ??
          (maxLines == 1 ? TextInputAction.next : TextInputAction.newline),
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        errorText: errorText,
        suffixText: suffixText,
        counterText: showCounter ? null : '',
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
