import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Standardized error state view with tonal error halo and retry action.
final class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10nOrNull;
    // Never show a raw exception dump; translate codes when possible.
    final shownMessage = l10n == null
        ? message
        : ValidationLocalizer.describeMessage(l10n, message);
    // Scrolls instead of overflowing when space is short (landscape phones,
    // large text, a small area under a pinned header).
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.7),
                  borderRadius: AppRadius.fullBorder,
                ),
                child: Icon(AppIcons.error, size: 32, color: colorScheme.error),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              if (shownMessage != null && shownMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  shownMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (retryLabel != null && onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: retryLabel!,
                  icon: AppIcons.refresh,
                  variant: AppButtonVariant.outlined,
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
