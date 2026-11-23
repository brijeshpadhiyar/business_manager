import 'package:material_ui/material_ui.dart';

/// Compact type-safe Material 3 dropdown field with validation and disabled support.
final class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.itemLabelBuilder,
    this.value,
    this.hint,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final T? value;
  final String? hint;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        enabled: enabled,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                itemLabelBuilder(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
    );
  }
}
