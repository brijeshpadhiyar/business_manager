import 'package:flutter/widgets.dart';

/// Descriptor linking a form field's [GlobalKey<FormFieldState>] with its
/// optional [FocusNode] so validation failures smoothly scroll the first
/// invalid field into view and move focus to it.
final class ValidatedFieldAnchor {
  const ValidatedFieldAnchor({required this.fieldKey, this.focusNode});

  final GlobalKey<FormFieldState<dynamic>> fieldKey;
  final FocusNode? focusNode;
}

/// Reusable Form UX helper implementing consistent validation timing,
/// focus management, and scroll-to-first-invalid-field behavior.
abstract final class FormValidationHelper {
  /// Validates [formKey] and, if invalid, scrolls the first failing field
  /// in [orderedAnchors] into view and requests focus on it.
  static bool validateAndFocusFirstInvalid({
    required GlobalKey<FormState> formKey,
    List<ValidatedFieldAnchor> orderedAnchors = const [],
  }) {
    final formState = formKey.currentState;
    if (formState == null) return false;
    final valid = formState.validate();
    if (valid) return true;

    for (final anchor in orderedAnchors) {
      final fieldState = anchor.fieldKey.currentState;
      if (fieldState != null && fieldState.hasError) {
        final ctx = anchor.fieldKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: 0.2,
          );
        }
        anchor.focusNode?.requestFocus();
        break;
      }
    }
    return false;
  }

  /// Ensures a specific keyed widget (such as a date picker or error card)
  /// is scrolled into view and optionally focused.
  static void scrollToAnchor(GlobalKey key, {FocusNode? focusNode}) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.2,
      );
    }
    focusNode?.requestFocus();
  }
}
