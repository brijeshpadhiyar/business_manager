import 'package:material_ui/material_ui.dart';

/// Type-safe Material 3 dropdown field with synchronized controlled value,
/// validation, disabled support, and clean bilingual text display.
final class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    this.fieldKey,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
  });

  final GlobalKey<FormFieldState<T>>? fieldKey;
  final String label;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final T? value;
  final String? hint;
  final String? errorText;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final safeValue = value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<T>(
      key: fieldKey ?? ValueKey<Object?>((safeValue, items.length)),
      initialValue: safeValue,
      isExpanded: true,
      validator: validator,
      // Live validation once the user changes the selection.
      autovalidateMode:
          autovalidateMode ??
          (validator != null ? AutovalidateMode.onUserInteraction : null),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        enabled: enabled,
      ),
      selectedItemBuilder: (context) => items
          .map(
            (item) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                itemLabelBuilder(item),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabelBuilder(item),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}
