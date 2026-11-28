import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/widgets/app_glass_surface.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

/// Smooth, reduced-motion-safe glass skeleton placeholder block with subtle
/// shimmer sweep that settles cleanly without unbounded infinite timers.
final class AppSkeletonBox extends StatelessWidget {
  const AppSkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = AppRadius.mdBorder,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.55 : 0.72,
        ),
        borderRadius: borderRadius,
      ),
    );

    if (AppMotion.reduceMotion(context)) {
      return box;
    }

    return box
        .animate(onPlay: (controller) => controller.repeat(count: 3))
        .shimmer(
          duration: const Duration(milliseconds: 1100),
          color: (isDark ? Colors.white : Colors.white).withValues(
            alpha: isDark ? 0.16 : 0.55,
          ),
        );
  }
}

/// Reusable frosted-glass skeleton list placeholder for loading screens.
final class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    return ListView.separated(
      padding: d.screenAll,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: d.sm),
      itemBuilder: (context, index) {
        return AppMotionEntrance(
          index: index,
          child: AppGlassSurface(
            glassStyle: AppGlassStyle.lightweight,
            blurSigma: 0,
            padding: d.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeletonBox(width: 160, height: d.isCompact ? 11 : 14),
                SizedBox(height: d.sm),
                AppSkeletonBox(width: 240, height: d.isCompact ? 9 : 11),
              ],
            ),
          ),
        );
      },
    );
  }
}
