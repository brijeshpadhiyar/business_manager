import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:material_ui/material_ui.dart';

/// Backwards-compatible facade delegating all feedback calls to
/// [AppMessageService] so every existing screen renders StitchFlow V1.3
/// Glassmorphism notifications consistently.
abstract final class AppFeedback {
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessageService.success(
      context,
      message,
      title: title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final l10n = context.l10nOrNull;
    AppMessageService.error(
      context,
      // Never show a raw exception dump; translate codes when possible.
      (l10n == null
              ? null
              : ValidationLocalizer.describeMessage(l10n, message)) ??
          message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
  }) {
    AppMessageService.warning(context, message, title: title);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    AppMessageService.info(context, message, title: title);
  }
}
