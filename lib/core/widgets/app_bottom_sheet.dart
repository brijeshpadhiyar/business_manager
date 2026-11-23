import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Adaptive sheet: opens as a smooth modal bottom sheet on compact mobile
/// viewports (`< 600dp`) and as a fade-scaled centered dialog on tablet/desktop.
final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);

    if (!sizeClass.isCompact) {
      final reduce = AppMotion.reduceMotion(context);
      return showModal<T>(
        context: context,
        configuration: FadeScaleTransitionConfiguration(
          transitionDuration: reduce ? Duration.zero : AppMotion.fast,
          reverseTransitionDuration: reduce ? Duration.zero : AppMotion.fast,
        ),
        builder: (dialogContext) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxDialogWidth,
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
                        child: AppHeading(title, level: AppHeadingLevel.h3),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Flexible(child: builder(dialogContext)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeading(title, level: AppHeadingLevel.h3),
            const SizedBox(height: AppSpacing.md),
            Flexible(child: builder(sheetContext)),
          ],
        ),
      ),
    );
  }
}
