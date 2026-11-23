import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Flavor-isolated persistence for local notification settings, dedupe plan digest,
/// and 24-hour alert cooldown state.
@lazySingleton
final class NotificationSettingsRepository {
  NotificationSettingsRepository(this._config);

  final AppConfig _config;

  String get _prefix => 'sf_${_config.flavor.name}_notif_';

  Future<NotificationSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      masterEnabled: prefs.getBool('${_prefix}master') ?? true,
      pendingWorkEnabled: prefs.getBool('${_prefix}pending_en') ?? true,
      pendingWorkDaysThreshold: prefs.getInt('${_prefix}pending_days') ?? 3,
      pendingWorkHour: prefs.getInt('${_prefix}pending_hr') ?? 10,
      pendingWorkMinute: prefs.getInt('${_prefix}pending_min') ?? 0,
      workerSettlementEnabled: prefs.getBool('${_prefix}settle_en') ?? true,
      workerSettlementWeekday:
          prefs.getInt('${_prefix}settle_wday') ?? DateTime.saturday,
      workerSettlementHour: prefs.getInt('${_prefix}settle_hr') ?? 18,
      workerSettlementMinute: prefs.getInt('${_prefix}settle_min') ?? 0,
      workerSettlementMinPaise:
          prefs.getInt('${_prefix}settle_min_paise') ?? 50000,
      dailySummaryEnabled: prefs.getBool('${_prefix}daily_en') ?? true,
      dailySummaryHour: prefs.getInt('${_prefix}daily_hr') ?? 20,
      dailySummaryMinute: prefs.getInt('${_prefix}daily_min') ?? 0,
      dailySummarySkipQuietDays:
          prefs.getBool('${_prefix}daily_skip_quiet') ?? true,
      backupReminderEnabled: prefs.getBool('${_prefix}backup_en') ?? true,
      backupReminderIntervalDays: prefs.getInt('${_prefix}backup_days') ?? 7,
      backupReminderHour: prefs.getInt('${_prefix}backup_hr') ?? 20,
      backupReminderMinute: prefs.getInt('${_prefix}backup_min') ?? 30,
      businessAlertsEnabled: prefs.getBool('${_prefix}alerts_en') ?? true,
      damagedAlertThreshold: prefs.getInt('${_prefix}alerts_dmg_qty') ?? 20,
      overdueAlertDays: prefs.getInt('${_prefix}alerts_overdue_days') ?? 14,
    );
  }

  Future<void> saveSettings(NotificationSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}master', s.masterEnabled);
    await prefs.setBool('${_prefix}pending_en', s.pendingWorkEnabled);
    await prefs.setInt('${_prefix}pending_days', s.pendingWorkDaysThreshold);
    await prefs.setInt('${_prefix}pending_hr', s.pendingWorkHour);
    await prefs.setInt('${_prefix}pending_min', s.pendingWorkMinute);
    await prefs.setBool('${_prefix}settle_en', s.workerSettlementEnabled);
    await prefs.setInt('${_prefix}settle_wday', s.workerSettlementWeekday);
    await prefs.setInt('${_prefix}settle_hr', s.workerSettlementHour);
    await prefs.setInt('${_prefix}settle_min', s.workerSettlementMinute);
    await prefs.setInt(
      '${_prefix}settle_min_paise',
      s.workerSettlementMinPaise,
    );
    await prefs.setBool('${_prefix}daily_en', s.dailySummaryEnabled);
    await prefs.setInt('${_prefix}daily_hr', s.dailySummaryHour);
    await prefs.setInt('${_prefix}daily_min', s.dailySummaryMinute);
    await prefs.setBool(
      '${_prefix}daily_skip_quiet',
      s.dailySummarySkipQuietDays,
    );
    await prefs.setBool('${_prefix}backup_en', s.backupReminderEnabled);
    await prefs.setInt('${_prefix}backup_days', s.backupReminderIntervalDays);
    await prefs.setInt('${_prefix}backup_hr', s.backupReminderHour);
    await prefs.setInt('${_prefix}backup_min', s.backupReminderMinute);
    await prefs.setBool('${_prefix}alerts_en', s.businessAlertsEnabled);
    await prefs.setInt('${_prefix}alerts_dmg_qty', s.damagedAlertThreshold);
    await prefs.setInt('${_prefix}alerts_overdue_days', s.overdueAlertDays);
  }

  Future<String?> getLastPlanDigest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_prefix}last_plan_hash');
  }

  Future<void> setLastPlanDigest(String digest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_prefix}last_plan_hash', digest);
  }

  Future<void> clearLastPlanDigest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}last_plan_hash');
  }

  Future<({int? firedAtUtcMillis, String? key})> getLastAlertCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      firedAtUtcMillis: prefs.getInt('${_prefix}last_alert_at'),
      key: prefs.getString('${_prefix}last_alert_key'),
    );
  }

  Future<void> recordAlertCooldown({
    required int firedAtUtcMillis,
    required String key,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefix}last_alert_at', firedAtUtcMillis);
    await prefs.setString('${_prefix}last_alert_key', key);
  }

  Future<bool> hasRequestedPermissionOnce() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_prefix}perm_requested') ?? false;
  }

  Future<void> markPermissionRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefix}perm_requested', true);
  }
}
