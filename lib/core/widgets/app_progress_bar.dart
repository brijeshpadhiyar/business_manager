import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:business_manager/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// Linear progress bar. `value == null` shows an indeterminate (running) bar.
final class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    this.value,
    this.tone,
    this.label,
    this.minHeight = 4,
    this.semanticLabel,
  });

  /// 0.0 – 1.0, clamped. `null` = indeterminate.
  final double? value;

  /// Semantic colour. Defaults to the primary colour.
  final AppStatusTone? tone;

  /// Optional caption shown above the bar.
  final String? label;
  final double minHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    final d = context.density;
    final color = switch (tone) {
      null => scheme.primary,
      AppStatusTone.good => semantic.goodStock,
      AppStatusTone.pending => semantic.pending,
      AppStatusTone.damaged => semantic.damaged,
      AppStatusTone.info => semantic.advanceCredit,
      AppStatusTone.neutral => scheme.onSurfaceVariant,
    };

    final bar = LinearProgressIndicator(
      value: value?.clamp(0.0, 1.0),
      minHeight: d.isCompact ? (minHeight * 0.75).clamp(2.5, minHeight) : minHeight,
      color: color,
      backgroundColor: scheme.surfaceContainerHighest,
      borderRadius: AppRadius.fullBorder,
      semanticsLabel: semanticLabel ?? label,
    );

    if (label == null) return bar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText(label!, variant: AppTextVariant.bodySmall),
        SizedBox(height: d.xs),
        bar,
      ],
    );
  }
}
