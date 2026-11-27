import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:material_ui/material_ui.dart';

/// Read-only, tappable form field shell shared by every picker field
/// (date, range, time, multi-date). Looks exactly like [AppTextField].
final class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.displayText,
    required this.icon,
    required this.onTap,
    this.hint,
    this.errorText,
    this.enabled = true,
    this.onClear,
  });

  final String label;
  final String displayText;
  final IconData icon;
  final VoidCallback onTap;
  final String? hint;
  final String? errorText;
  final bool enabled;

  /// When set and a value is shown, a clear button replaces the icon.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = displayText.isNotEmpty;
    final showClear = onClear != null && hasValue && enabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      value: displayText,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: InputDecorator(
          isEmpty: !hasValue,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            errorText: errorText,
            enabled: enabled,
            suffixIcon: showClear
                ? IconButton(
                    icon: const Icon(AppIcons.close, size: AppSizing.iconMd),
                    tooltip: MaterialLocalizations.of(context)
                        .deleteButtonTooltip,
                    onPressed: onClear,
                  )
                : Icon(icon, size: AppSizing.iconMd),
          ),
          child: Text(
            displayText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
