import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:material_ui/material_ui.dart';

/// Smoothly animates integer counts or integer paise currency values on
/// dashboards and summary headers using tabular numerals.
///
/// Uses `FittedBox(fit: BoxFit.scaleDown)` so important monetary values and
/// stock counts never silently truncate with an ellipsis on narrow phones.
final class AppAnimatedNumber extends StatefulWidget {
  const AppAnimatedNumber({
    super.key,
    required this.value,
    this.isCurrencyPaise = false,
    this.suffix,
    this.style,
    this.color,
    this.alignment = Alignment.centerLeft,
  });

  final int value;
  final bool isCurrencyPaise;
  final String? suffix;
  final TextStyle? style;
  final Color? color;
  final AlignmentGeometry alignment;

  @override
  State<AppAnimatedNumber> createState() => _AppAnimatedNumberState();
}

final class _AppAnimatedNumberState extends State<AppAnimatedNumber> {
  late double _beginValue;

  @override
  void initState() {
    super.initState();
    _beginValue = 0;
  }

  @override
  void didUpdateWidget(covariant AppAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _beginValue = oldWidget.value.toDouble();
    } else {
      // Keep steady on rebuilds when value did not change (no redundant animation).
      _beginValue = widget.value.toDouble();
    }
  }

  String _format(int current) {
    if (widget.isCurrencyPaise) {
      return MoneyFormatter.formatPaise(current);
    }
    return widget.suffix != null && widget.suffix!.isNotEmpty
        ? '$current ${widget.suffix}'
        : '$current';
  }

  Widget _buildFittedText(String text, TextStyle style) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: widget.alignment,
      child: Text(text, style: style, maxLines: 1, softWrap: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        widget.style ??
        Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    final effectiveStyle = AppTypography.tabular(
      widget.color != null
          ? baseStyle.copyWith(color: widget.color)
          : baseStyle,
    );

    final duration = AppMotion.duration(context, AppMotion.numberCount);
    final target = widget.value.toDouble();
    if (duration == Duration.zero || _beginValue == target) {
      return _buildFittedText(_format(widget.value), effectiveStyle);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _beginValue, end: target),
      duration: duration,
      curve: AppMotion.standardCurve,
      builder: (context, animatedValue, _) {
        return _buildFittedText(_format(animatedValue.round()), effectiveStyle);
      },
    );
  }
}
