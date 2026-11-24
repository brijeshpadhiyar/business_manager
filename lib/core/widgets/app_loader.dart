import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_glass_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Consistent frosted-glass loading indicator with smooth fade-scale entrance
/// and optional localized label.
final class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size = 26});

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: AppMotionEntrance(
          slideOffsetY: 10,
          child: AppGlassSurface(
            borderRadius: AppRadius.xlBorder,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: colorScheme.secondary,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
