import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Subtle, non-blocking dismissible tip bar shown once the first time a user
/// visits a screen when `showNewScreenHints` is enabled.
final class ScreenFirstVisitHint extends StatelessWidget {
  const ScreenFirstVisitHint({
    super.key,
    required this.screenId,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String screenId;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GuideCubit?>();
    if (cubit == null) return const SizedBox.shrink();

    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, state) {
        if (!state.shouldShowHintForScreen(screenId)) {
          return const SizedBox.shrink();
        }
        final l10n = context.l10n;
        final localeCode = Localizations.localeOf(context).languageCode;
        final colorScheme = Theme.of(context).colorScheme;

        return Padding(
          padding: padding,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
              borderRadius: AppRadius.lgBorder,
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.tip,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.guideFirstVisitHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => cubit.startScreenTour(
                    screenId,
                    localeCode: localeCode,
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(l10n.guideFirstVisitAction),
                ),
                IconButton(
                  tooltip: l10n.guideActionSkip,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    AppIcons.close,
                    size: 16,
                    color: colorScheme.onSecondaryContainer,
                  ),
                  onPressed: () => cubit.markScreenHintDismissed(screenId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
