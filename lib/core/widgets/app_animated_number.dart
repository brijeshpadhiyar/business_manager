import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:material_ui/material_ui.dart';

/// Smoothly animates integer counts or integer paise currency values on
/// dashboards and summary headers using tabular numerals.
///
/// Automatically snaps without animation when reduced motion is enabled.
final class AppAnimatedNumber extends StatelessWidget {
  const AppAnimatedNumber({
    super.key,
    required this.value,
    this.isCurrencyPaise = false,
    this.suffix,
    this.style,
    this.color,
    this.maxLines = 1,
  });

  final int value;
  final bool isCurrencyPaise;
  final String? suffix;
  final TextStyle? style;
  final Color? color;
  final int maxLines;

  String _format(int current) {
    if (isCurrencyPaise) {
      return MoneyFormatter.formatPaise(current);
    }
    return suffix != null && suffix!.isNotEmpty
        ? '$current $suffix'
        : '$current';
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle =
        style ??
        Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700) ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
    final effectiveStyle = AppTypography.tabular(
      color != null ? baseStyle.copyWith(color: color) : baseStyle,
    );

    final duration = AppMotion.duration(context, AppMotion.numberCount);
    if (duration == Duration.zero) {
      return Text(
        _format(value),
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: AppMotion.standardCurve,
      builder: (context, animatedValue, _) {
        return Text(
          _format(animatedValue.round()),
          style: effectiveStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
