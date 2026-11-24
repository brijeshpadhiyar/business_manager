import 'dart:async';

import 'package:business_manager/core/validation/validation_error.dart';
import 'package:business_manager/core/widgets/app_text_field.dart';
import 'package:material_ui/material_ui.dart';

/// Consistent glass-styled search input with built-in clear action, optional
/// debounce timer, and standardized max-length enforcement
/// (`ValidationLimits.maxSearchLength`).
final class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onClear,
    this.debounceDuration,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Duration? debounceDuration;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

final class _AppSearchFieldState extends State<AppSearchField> {
  TextEditingController? _internalCtrl;
  String _currentText = '';
  Timer? _debounce;

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

  void _emitChanged(String value) {
    _debounce?.cancel();
    final delay = widget.debounceDuration;
    if (delay == null || delay == Duration.zero) {
      widget.onChanged?.call(value);
      return;
    }
    _debounce = Timer(delay, () {
      if (mounted) widget.onChanged?.call(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
                _debounce?.cancel();
                _ctrl.clear();
                widget.onChanged?.call('');
                widget.onClear?.call();
              },
            )
          : null,
      onChanged: _emitChanged,
    );
  }
}
