import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Lightweight, reduced-motion-friendly skeleton placeholder block.
/// Uses clean tonal surface contrast without unbounded looping timers that
/// drain battery or interfere with deterministic UI tests.
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: borderRadius,
      ),
    );
  }
}

/// Reusable skeleton list placeholder for loading screens.
final class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: AppSpacing.screenAll,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        return Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(width: 160, height: 14),
              SizedBox(height: AppSpacing.sm),
              AppSkeletonBox(width: 240, height: 11),
            ],
          ),
        );
      },
    );
  }
}
