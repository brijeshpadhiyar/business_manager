import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

/// Adaptive Material 3 dialog helper with max-width constraint and consistent actions.
final class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.isDestructive = false,
  });

  final String title;
  final Widget content;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppDialog(
        title: title,
        content: Text(message),
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxDialogWidth),
        child: content,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      actions: [
        if (cancelLabel != null)
          AppButton(
            label: cancelLabel!,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        if (confirmLabel != null)
          AppButton(
            label: confirmLabel!,
            variant: isDestructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            onPressed: onConfirm ?? () => Navigator.of(context).pop(true),
          ),
      ],
    );
  }
}
