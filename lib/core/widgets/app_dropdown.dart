import 'package:material_ui/material_ui.dart';

/// Type-safe Material 3 dropdown field with synchronized controlled value,
/// validation, disabled support, and clean bilingual text display.
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
    final safeValue = value != null && items.contains(value) ? value : null;

    return DropdownButtonFormField<T>(
      key: ValueKey<Object?>((safeValue, items.length)),
      initialValue: safeValue,
      isExpanded: true,
      validator: validator,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
