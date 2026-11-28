import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:business_manager/core/widgets/app_empty_visual.dart';
import 'package:material_ui/material_ui.dart';

/// Standardized empty state view with animated Lottie / GIF / icon visual,
/// localized title, subtitle, and optional primary CTA.
final class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.animation,
    this.lottieAsset,
    this.gifAsset,
    this.animateIcon = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Optional explicit animation category override; defaults to auto-mapping
  /// from [icon].
  final AppEmptyAnimation? animation;

  /// Optional custom Lottie JSON asset path overriding [animation].
  final String? lottieAsset;

  /// Optional GIF/raster asset path displayed instead of Lottie when provided.
  final String? gifAsset;

  /// Whether the fallback icon halo uses subtle motion when active.
  final bool animateIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final d = context.density;
    // Scrolls instead of overflowing when space is short (landscape phones,
    // large text, a small area under a pinned header).
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(d.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppEmptyVisual(
                icon: icon,
                animation: animation,
                lottieAsset: lottieAsset,
                gifAsset: gifAsset,
                animateIcon: animateIcon,
              ),
              SizedBox(height: d.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                SizedBox(height: d.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: d.lg),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
