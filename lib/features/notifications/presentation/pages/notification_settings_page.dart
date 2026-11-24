import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/notifications/presentation/bloc/notification_settings_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// `/settings/notifications` — Offline Android local reminders & alerts hub.
final class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationSettingsCubit>(
      create: (_) => getIt<NotificationSettingsCubit>()..load(),
      child: const _NotificationSettingsView(),
    );
  }
}

final class _NotificationSettingsView extends StatelessWidget {
  const _NotificationSettingsView();

  String _formatTime(int hour, int minute) {
    return AppDateTimeFormatter.formatTimeFromHourMinute(
      hour,
      minute,
      includeIstSuffix: true,
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required int initialHour,
    required int initialMinute,
    required ValueChanged<({int hour, int minute})> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked != null) {
      onPicked((hour: picked.hour, minute: picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.notificationsHeading,
      contentWidth: AppContentWidth.narrow,
      body: BlocBuilder<NotificationSettingsCubit, NotificationSettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const AppSkeletonList(itemCount: 4);
          }

          final cubit = context.read<NotificationSettingsCubit>();
          final s = state.settings;

          final (permLabel, permTone) = switch (state.permissionStatus) {
            NotificationPermissionStatus.granted => (
              l10n.notificationsPermGranted,
              AppStatusTone.good,
            ),
            NotificationPermissionStatus.notRequested => (
              l10n.notificationsPermNeeded,
              AppStatusTone.pending,
            ),
            NotificationPermissionStatus.denied => (
              l10n.notificationsPermBlocked,
              AppStatusTone.damaged,
            ),
            NotificationPermissionStatus.unsupported => (
              l10n.notificationsPermUnsupported,
              AppStatusTone.neutral,
            ),
          };

          return ListView(
            children: [
              // 1. OS Permission Status Card
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppHeading(
                            l10n.notificationsStatusTitle,
                            level: AppHeadingLevel.h3,
                          ),
                        ),
                        AppStatusBadge(label: permLabel, tone: permTone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(switch (state.permissionStatus) {
                      NotificationPermissionStatus.granted =>
                        l10n.notificationsStatusGrantedDesc,
                      NotificationPermissionStatus.denied =>
                        l10n.notificationsStatusBlockedDesc,
                      _ => l10n.notificationsStatusNeededDesc,
                    }, variant: AppTextVariant.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (state.permissionStatus ==
                                NotificationPermissionStatus.notRequested ||
                            state.permissionStatus ==
                                NotificationPermissionStatus.denied)
                          AppButton(
                            label: l10n.notificationsAllowAction,
                            icon: Icons.notifications_active_outlined,
                            isLoading: state.isSaving,
                            onPressed: cubit.requestPermission,
                          ),
                        if (state.permissionStatus ==
                            NotificationPermissionStatus.granted)
                          AppButton(
                            label: l10n.notificationsSendTestAction,
                            icon: Icons.send_outlined,
                            variant: AppButtonVariant.outlined,
                            onPressed: () async {
                              final ok = await cubit.sendTestNotification(
                                title: l10n.notificationsTestTitle,
                                body: l10n.notificationsTestBody,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                AppFeedback.showSuccess(
                                  context,
                                  l10n.notificationsTestSent,
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Master Toggle
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppSwitch(
                  label: l10n.notificationsMasterToggle,
                  subtitle: l10n.notificationsMasterSubtitle,
                  value: s.masterEnabled,
                  onChanged: (v) =>
                      cubit.updateSettings(s.copyWith(masterEnabled: v)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (s.masterEnabled) ...[
                // 3. Pending Work Reminder (1001)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSwitch(
                        label: l10n.notificationsPendingWorkTitle,
                        subtitle: l10n.notificationsPendingWorkDesc,
                        value: s.pendingWorkEnabled,
                        onChanged: (v) => cubit.updateSettings(
                          s.copyWith(pendingWorkEnabled: v),
                        ),
                      ),
                      if (s.pendingWorkEnabled) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          l10n.notificationsPendingDaysLabel,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final d in const [1, 2, 3, 5, 7])
                              ChoiceChip(
                                label: Text('${d}d'),
                                selected: s.pendingWorkDaysThreshold == d,
                                onSelected: (_) => cubit.updateSettings(
                                  s.copyWith(pendingWorkDaysThreshold: d),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton(
                          label:
                              '${l10n.notificationsTimeLabel}: ${_formatTime(s.pendingWorkHour, s.pendingWorkMinute)}',
                          icon: Icons.schedule_rounded,
                          variant: AppButtonVariant.text,
                          onPressed: () => _pickTime(
                            context,
                            initialHour: s.pendingWorkHour,
                            initialMinute: s.pendingWorkMinute,
                            onPicked: (t) => cubit.updateSettings(
                              s.copyWith(
                                pendingWorkHour: t.hour,
                                pendingWorkMinute: t.minute,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 4. Worker Settlement Reminder (1002)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSwitch(
                        label: l10n.notificationsSettlementTitle,
                        subtitle: l10n.notificationsSettlementDesc,
                        value: s.workerSettlementEnabled,
                        onChanged: (v) => cubit.updateSettings(
                          s.copyWith(workerSettlementEnabled: v),
                        ),
                      ),
                      if (s.workerSettlementEnabled) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          l10n.notificationsMinAmountLabel,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final paise in const [
                              10000,
                              50000,
                              100000,
                              500000,
                            ])
                              ChoiceChip(
                                label: Text(MoneyFormatter.formatPaise(paise)),
                                selected: s.workerSettlementMinPaise == paise,
                                onSelected: (_) => cubit.updateSettings(
                                  s.copyWith(workerSettlementMinPaise: paise),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppButton(
                          label:
                              '${l10n.notificationsTimeLabel}: ${_formatTime(s.workerSettlementHour, s.workerSettlementMinute)}',
                          icon: Icons.schedule_rounded,
                          variant: AppButtonVariant.text,
                          onPressed: () => _pickTime(
                            context,
                            initialHour: s.workerSettlementHour,
                            initialMinute: s.workerSettlementMinute,
                            onPicked: (t) => cubit.updateSettings(
                              s.copyWith(
                                workerSettlementHour: t.hour,
                                workerSettlementMinute: t.minute,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 5. Daily Summary Reminder (1003)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSwitch(
                        label: l10n.notificationsDailySummaryTitle,
                        subtitle: l10n.notificationsDailySummaryDesc,
                        value: s.dailySummaryEnabled,
                        onChanged: (v) => cubit.updateSettings(
                          s.copyWith(dailySummaryEnabled: v),
                        ),
                      ),
                      if (s.dailySummaryEnabled) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppSwitch(
                          label: l10n.notificationsSkipQuietDaysLabel,
                          value: s.dailySummarySkipQuietDays,
                          onChanged: (v) => cubit.updateSettings(
                            s.copyWith(dailySummarySkipQuietDays: v),
                          ),
                        ),
                        AppButton(
                          label:
                              '${l10n.notificationsTimeLabel}: ${_formatTime(s.dailySummaryHour, s.dailySummaryMinute)}',
                          icon: Icons.schedule_rounded,
                          variant: AppButtonVariant.text,
                          onPressed: () => _pickTime(
                            context,
                            initialHour: s.dailySummaryHour,
                            initialMinute: s.dailySummaryMinute,
                            onPicked: (t) => cubit.updateSettings(
                              s.copyWith(
                                dailySummaryHour: t.hour,
                                dailySummaryMinute: t.minute,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 6. Backup Reminder (1004)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSwitch(
                        label: l10n.notificationsBackupTitle,
                        subtitle: l10n.notificationsBackupDesc,
                        value: s.backupReminderEnabled,
                        onChanged: (v) => cubit.updateSettings(
                          s.copyWith(backupReminderEnabled: v),
                        ),
                      ),
                      if (s.backupReminderEnabled) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppText(
                          l10n.notificationsBackupIntervalLabel,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final d in const [3, 7, 14, 30])
                              ChoiceChip(
                                label: Text('${d}d'),
                                selected: s.backupReminderIntervalDays == d,
                                onSelected: (_) => cubit.updateSettings(
                                  s.copyWith(backupReminderIntervalDays: d),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 7. Important Local Business Alerts (1005)
                AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppSwitch(
                    label: l10n.notificationsAlertsTitle,
                    subtitle: l10n.notificationsAlertsDesc,
                    value: s.businessAlertsEnabled,
                    onChanged: (v) => cubit.updateSettings(
                      s.copyWith(businessAlertsEnabled: v),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 8. Offline Privacy & OEM Battery Guidance Note
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeading(
                      l10n.notificationsPrivacyOemTitle,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.notificationsPrivacyOemBody,
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
