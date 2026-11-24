import 'package:business_manager/core/validation/validation_error.dart';
import 'package:business_manager/core/widgets/app_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// Consistent glass-styled search input with built-in clear action and
/// standardized max-length enforcement (`ValidationLimits.maxSearchLength`).
final class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

final class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _internalCtrl;
  String _currentText = '';

  TextEditingController get _ctrl =>
      widget.controller ?? (_internalCtrl ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _currentText = _ctrl.text;
    _ctrl.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleTextChanged);
      _ctrl.addListener(_handleTextChanged);
      _currentText = _ctrl.text;
    }
  }

  void _handleTextChanged() {
    if (!mounted) return;
    if (_currentText != _ctrl.text) {
      setState(() => _currentText = _ctrl.text);
    }
  }

  @override
  void dispose() {
    _ctrl.removeListener(_handleTextChanged);
    _internalCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _ctrl,
      label: widget.label,
      hint: widget.hint,
      prefixIcon: Icons.search_rounded,
      maxLength: ValidationLimits.maxSearchLength,
      textInputAction: TextInputAction.search,
      suffixIcon: _currentText.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Clear',
              onPressed: () {
                _ctrl.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
            )
          : null,
      onChanged: widget.onChanged,
    );
  }
}
