import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_heading.dart';
import 'package:material_ui/material_ui.dart';

/// Adaptive sheet: opens as a modal bottom sheet on compact mobile viewports
/// (`< 600dp`) and as a centered constrained dialog on tablet/desktop (`>= 600dp`).
final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);

    if (!sizeClass.isCompact) {
      return showDialog<T>(
        context: context,
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
                  AppHeading(title, level: AppHeadingLevel.h3),
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
