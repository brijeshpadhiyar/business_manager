import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
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
      return [const SizedBox(height: AppSpacing.md), actionsBuilder(ctx)];
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
                  borderRadius: AppRadius.xlBorder,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    enabled: false, // v1.4 soft elevation: opaque surfaces
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.dialogGlassFill,
                        borderRadius: AppRadius.xlBorder,
                        border: Border.all(
                          color: tokens.glassBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: AppSpacing.screenAll,
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
                                  icon: const Icon(AppIcons.close, size: 20),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Divider(),
                            const SizedBox(height: AppSpacing.md),
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
        const topRadius = BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        );

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: topRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              enabled: false, // v1.4 soft elevation: opaque surfaces
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
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    // Above the keyboard when it is open, otherwise clear of
                    // the home indicator / gesture bar.
                    (MediaQuery.viewInsetsOf(sheetContext).bottom >
                                MediaQuery.viewPaddingOf(sheetContext).bottom
                            ? MediaQuery.viewInsetsOf(sheetContext).bottom
                            : MediaQuery.viewPaddingOf(sheetContext).bottom) +
                        AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                            borderRadius: AppRadius.fullBorder,
                          ),
                        ),
                      ),
                      AppHeading(title, level: AppHeadingLevel.h3),
                      const SizedBox(height: AppSpacing.md),
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
