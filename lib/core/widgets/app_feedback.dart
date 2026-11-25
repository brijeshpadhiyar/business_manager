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
  }) {
    AppMessageService.success(context, message, title: title);
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    AppMessageService.error(
      context,
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
