import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/widgets/app_heading.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Adaptive frosted-glass sheet: opens as a smooth BackdropFilter glass modal
/// bottom sheet on compact mobile viewports (`< 600dp`) and as a fade-scaled
/// frosted-glass centered dialog on tablet/desktop.
final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    WidgetBuilder? actionsBuilder,
  }) {
    // Content that is a plain Column cannot scroll by itself; on a short
    // phone with the keyboard open it would overflow. Make it scrollable.
    Widget body(BuildContext ctx) {
      final content = builder(ctx);
      if (content is Column) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: content,
        );
      }
      return content;
    }

    // Primary actions stay pinned below the scrolling content.
    List<Widget> pinnedActions(BuildContext ctx) {
      if (actionsBuilder == null) return const [];
      return [SizedBox(height: ctx.density.md), actionsBuilder(ctx)];
    }

    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    final reduce = AppMotion.reduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barrierColor = Colors.black.withValues(alpha: isDark ? 0.56 : 0.34);

    if (!sizeClass.isCompact) {
      return showModal<T>(
        context: context,
        configuration: FadeScaleTransitionConfiguration(
          barrierColor: barrierColor,
          transitionDuration: reduce
              ? Duration.zero
              : const Duration(milliseconds: 200),
          reverseTransitionDuration: reduce
              ? Duration.zero
              : const Duration(milliseconds: 150),
        ),
        builder: (dialogContext) {
          final tokens = dialogContext.surfaceTokens;
          final d = dialogContext.density;
          return Dialog(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizing.maxDialogWidth,
              ),
              child: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: d.radiusXlBorder,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: AppGlassQuality.resolve(
                        dialogContext,
                      ).chromeBlurSigma,
                      sigmaY: AppGlassQuality.resolve(
                        dialogContext,
                      ).chromeBlurSigma,
                    ),
                    enabled: AppGlassQuality.resolve(
                      dialogContext,
                    ).enableBackdropBlur,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.dialogGlassFill,
                        borderRadius: d.radiusXlBorder,
                        border: Border.all(
                          color: tokens.glassBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: d.screenAll,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppHeading(
                                    title,
                                    level: AppHeadingLevel.h3,
                                  ),
                                ),
                                IconButton(
                                  tooltip: MaterialLocalizations.of(
                                    dialogContext,
                                  ).closeButtonTooltip,
                                  constraints: BoxConstraints(
                                    minWidth: d.touchTargetMin,
                                    minHeight: d.touchTargetMin,
                                  ),
                                  padding: d.isCompact ? EdgeInsets.zero : null,
                                  icon: Icon(AppIcons.close, size: d.iconMd),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                ),
                              ],
                            ),
                            SizedBox(height: d.sm),
                            const Divider(),
                            SizedBox(height: d.md),
                            Flexible(child: body(dialogContext)),
                            ...pinnedActions(dialogContext),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      sheetAnimationStyle: AnimationStyle(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        reverseDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: AppMotion.standardCurve,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetContext) {
        final tokens = sheetContext.surfaceTokens;
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final d = sheetContext.density;
        final topRadius = BorderRadius.vertical(
          top: Radius.circular(d.radiusXl),
        );

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: topRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppGlassQuality.resolve(sheetContext).chromeBlurSigma,
                sigmaY: AppGlassQuality.resolve(sheetContext).chromeBlurSigma,
              ),
              enabled: AppGlassQuality.resolve(
                sheetContext,
              ).enableBackdropBlur,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.dialogGlassFill,
                  borderRadius: topRadius,
                  border: Border(
                    top: BorderSide(color: tokens.glassBorder, width: 1.3),
                    left: BorderSide(color: tokens.glassBorder, width: 0.6),
                    right: BorderSide(color: tokens.glassBorder, width: 0.6),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    d.sheetPadding,
                    d.sm,
                    d.sheetPadding,
                    // Above the keyboard when it is open, otherwise clear of
                    // the home indicator / gesture bar.
                    (MediaQuery.viewInsetsOf(sheetContext).bottom >
                                MediaQuery.viewPaddingOf(sheetContext).bottom
                            ? MediaQuery.viewInsetsOf(sheetContext).bottom
                            : MediaQuery.viewPaddingOf(sheetContext).bottom) +
                        d.sheetPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: d.isCompact ? 32 : 40,
                          height: 4,
                          margin: EdgeInsets.only(bottom: d.md),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: AppRadius.fullBorder,
                          ),
                        ),
                      ),
                      AppHeading(title, level: AppHeadingLevel.h3),
                      SizedBox(height: d.md),
                      Flexible(child: body(sheetContext)),
                      ...pinnedActions(sheetContext),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
