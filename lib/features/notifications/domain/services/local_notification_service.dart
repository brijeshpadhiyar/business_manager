import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';

/// Platform-agnostic contract for local Android notifications (mockable in tests).
abstract interface class LocalNotificationService {
  /// Initializes plugin, registers Android notification channels, and attaches
  /// notification tap callback (validated against strict route allowlist).
  Future<void> initialize({required void Function(String route) onDeepLinkTap});

  /// Returns whether OS notifications are currently enabled/permitted.
  Future<NotificationPermissionStatus> checkPermissionStatus();

  /// Requests Android 13+ (`POST_NOTIFICATIONS`) permission contextually.
  Future<NotificationPermissionStatus> requestPermission();

  /// Applies [plan] idempotently: cancels resolved IDs and schedules/fires active ones.
  Future<void> syncPlan(NotificationSyncPlan plan);

  /// Fires an immediate test notification so the user can verify sound & visibility.
  Future<bool> showTestNotification({
    required String title,
    required String body,
  });

  /// Cancels all scheduled/active StitchFlow local notifications.
  Future<void> cancelAll();

  /// Returns and clears any deep-link route from cold-launching via a notification tap.
  Future<String?> consumeLaunchRoute();
}
