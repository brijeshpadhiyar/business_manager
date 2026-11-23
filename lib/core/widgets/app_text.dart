import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:material_ui/material_ui.dart';

enum AppTextVariant { bodyLarge, bodyMedium, bodySmall, label, numeric }

/// Theme-aware text widget supporting tabular numeric alignment and clean
/// English/Gujarati overflow handling.
final class AppText extends StatelessWidget {
  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final AppTextVariant variant;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    TextStyle baseStyle = switch (variant) {
      AppTextVariant.bodyLarge => textTheme.bodyLarge!,
      AppTextVariant.bodyMedium => textTheme.bodyMedium!,
      AppTextVariant.bodySmall => textTheme.bodySmall!,
      AppTextVariant.label => textTheme.labelMedium!,
      AppTextVariant.numeric => AppTypography.tabular(
        textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
      ),
    };

    if (color != null || fontWeight != null) {
      baseStyle = baseStyle.copyWith(color: color, fontWeight: fontWeight);
    }

    return Text(
      text,
      style: baseStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }
}
