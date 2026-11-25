import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:business_manager/features/notifications/domain/calculators/notification_plan_calculator.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/timezone.dart' as tz;

/// Real Android `flutter_local_notifications` v23 adapter using
/// `AndroidScheduleMode.inexactAllowWhileIdle` (zero exact-alarm permissions,
/// 100% offline, flavor-isolated via Android applicationId).
@LazySingleton(as: LocalNotificationService)
final class FlutterLocalNotificationsAdapter
    implements LocalNotificationService {
  FlutterLocalNotificationsAdapter(this._settingsRepo);

  final NotificationSettingsRepository _settingsRepo;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _pendingLaunchRoute;

  static bool get _isSupportedPlatform =>
      !isFlutterTestEnv && isAndroidPlatform;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required void Function(String route) onDeepLinkTap,
  }) async {
    if (_initialized || !_isSupportedPlatform) return;
    _initialized = true;

    try {
      const initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (NotificationPlanCalculator.isAllowedDeepLinkRoute(route)) {
            onDeepLinkTap(route!);
          }
        },
      );

      final android = _android;
      if (android != null) {
        const channels = <AndroidNotificationChannel>[
          AndroidNotificationChannel(
            'sf_pending_work',
            'Pending Workshop Returns',
            description: 'Reminders for unreturned karigar stock issues.',
            importance: Importance.defaultImportance,
          ),
          AndroidNotificationChannel(
            'sf_worker_settlement',
            'Worker Settlements',
            description: 'Weekly reminders for outstanding karigar payables.',
            importance: Importance.defaultImportance,
          ),
          AndroidNotificationChannel(
            'sf_daily_summary',
            'Daily Workshop Summary',
            description: 'Evening recap of daily issues, returns, and labour.',
            importance: Importance.defaultImportance,
          ),
          AndroidNotificationChannel(
            'sf_backup_reminder',
            'Offline Backup Reminders',
            description: 'Periodic reminders to save a local .zip backup.',
            importance: Importance.defaultImportance,
          ),
          AndroidNotificationChannel(
            'sf_business_alerts',
            'Important Workshop Alerts',
            description: 'Local alerts for high damaged stock or overdue work.',
            importance: Importance.high,
          ),
        ];
        for (final ch in channels) {
          await android.createNotificationChannel(ch);
        }
      }

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp == true) {
        final route = launchDetails?.notificationResponse?.payload;
        if (NotificationPlanCalculator.isAllowedDeepLinkRoute(route)) {
          _pendingLaunchRoute = route;
        }
      }
    } catch (_) {
      // Never block app startup if notification channels fail on an OEM ROM.
    }
  }

  @override
  Future<NotificationPermissionStatus> checkPermissionStatus() async {
    if (!_isSupportedPlatform) {
      return NotificationPermissionStatus.unsupported;
    }
    try {
      final enabled = await _android?.areNotificationsEnabled();
      if (enabled == true) return NotificationPermissionStatus.granted;
      final requestedOnce = await _settingsRepo.hasRequestedPermissionOnce();
      return requestedOnce
          ? NotificationPermissionStatus.denied
          : NotificationPermissionStatus.notRequested;
    } catch (_) {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    if (!_isSupportedPlatform) {
      return NotificationPermissionStatus.unsupported;
    }
    try {
      await _settingsRepo.markPermissionRequested();
      final granted = await _android?.requestNotificationsPermission();
      if (granted == true) return NotificationPermissionStatus.granted;
      final enabled = await _android?.areNotificationsEnabled();
      return enabled == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
    } catch (_) {
      return NotificationPermissionStatus.denied;
    }
  }

  @override
  Future<void> syncPlan(NotificationSyncPlan plan) async {
    if (!_isSupportedPlatform) return;
    try {
      for (final id in plan.idsToCancel) {
        await _plugin.cancel(id: id);
      }

      for (final item in plan.planned) {
        final isHigh = item.category == NotificationCategory.businessAlerts;
        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            item.channelId,
            _channelDisplayName(item.category),
            importance: isHigh ? Importance.high : Importance.defaultImportance,
            priority: isHigh ? Priority.high : Priority.defaultPriority,
            visibility: item.privacyPrivate
                ? NotificationVisibility.private
                : NotificationVisibility.public,
          ),
        );

        if (item.isImmediateAlert) {
          await _plugin.show(
            id: item.id,
            title: item.title,
            body: item.body,
            notificationDetails: details,
            payload: item.payloadRoute,
          );
        } else {
          final tzDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
            IstDateTimeHelper.istLocation,
            item.scheduledAtUtcMillis,
          );
          await _plugin.zonedSchedule(
            id: item.id,
            scheduledDate: tzDate,
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            title: item.title,
            body: item.body,
            payload: item.payloadRoute,
          );
        }
      }
    } catch (_) {
      // Fail safely without interrupting workshop workflows.
    }
  }

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async {
    if (!_isSupportedPlatform) return false;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'sf_daily_summary',
          'Daily Workshop Summary',
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id: 1099,
        title: title,
        body: body,
        notificationDetails: details,
        payload: '/daily-summary',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> cancelAll() async {
    if (!_isSupportedPlatform) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  @override
  Future<String?> consumeLaunchRoute() async {
    final r = _pendingLaunchRoute;
    _pendingLaunchRoute = null;
    return r;
  }

  static String _channelDisplayName(NotificationCategory c) => switch (c) {
    NotificationCategory.pendingWork => 'Pending Workshop Returns',
    NotificationCategory.workerSettlement => 'Worker Settlements',
    NotificationCategory.dailySummary => 'Daily Workshop Summary',
    NotificationCategory.backupReminder => 'Offline Backup Reminders',
    NotificationCategory.businessAlerts => 'Important Workshop Alerts',
  };
}
