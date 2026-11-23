import 'package:business_manager/features/notifications/data/repositories/notification_settings_repository.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

final class NotificationSettingsState {
  const NotificationSettingsState({
    this.isLoading = true,
    this.isSaving = false,
    this.permissionStatus = NotificationPermissionStatus.notRequested,
    this.settings = const NotificationSettings(),
    this.feedbackMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final NotificationPermissionStatus permissionStatus;
  final NotificationSettings settings;
  final String? feedbackMessage;

  NotificationSettingsState copyWith({
    bool? isLoading,
    bool? isSaving,
    NotificationPermissionStatus? permissionStatus,
    NotificationSettings? settings,
    String? feedbackMessage,
    bool clearFeedback = false,
  }) {
    return NotificationSettingsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      permissionStatus: permissionStatus ?? this.permissionStatus,
      settings: settings ?? this.settings,
      feedbackMessage: clearFeedback
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }
}

@injectable
final class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(
    this._settingsRepo,
    this._service,
    this._coordinator,
  ) : super(const NotificationSettingsState());

  final NotificationSettingsRepository _settingsRepo;
  final LocalNotificationService _service;
  final NotificationRefreshCoordinator _coordinator;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearFeedback: true));
    final settings = await _settingsRepo.loadSettings();
    final perm = await _service.checkPermissionStatus();
    if (isClosed) return;
    emit(
      state.copyWith(
        isLoading: false,
        settings: settings,
        permissionStatus: perm,
      ),
    );
  }

  Future<void> requestPermission() async {
    emit(state.copyWith(isSaving: true, clearFeedback: true));
    final perm = await _service.requestPermission();
    if (perm == NotificationPermissionStatus.granted) {
      await _coordinator.refreshIfPermitted(forceReschedule: true);
    }
    if (isClosed) return;
    emit(state.copyWith(isSaving: false, permissionStatus: perm));
  }

  Future<void> updateSettings(NotificationSettings next) async {
    final sanitized = next.copyWith(
      pendingWorkDaysThreshold: next.pendingWorkDaysThreshold.clamp(1, 365),
      pendingWorkHour: next.pendingWorkHour.clamp(0, 23),
      pendingWorkMinute: next.pendingWorkMinute.clamp(0, 59),
      workerSettlementMinPaise: next.workerSettlementMinPaise < 0
          ? 0
          : next.workerSettlementMinPaise,
      workerSettlementHour: next.workerSettlementHour.clamp(0, 23),
      workerSettlementMinute: next.workerSettlementMinute.clamp(0, 59),
      dailySummaryHour: next.dailySummaryHour.clamp(0, 23),
      dailySummaryMinute: next.dailySummaryMinute.clamp(0, 59),
      backupReminderIntervalDays: next.backupReminderIntervalDays.clamp(1, 365),
    );
    emit(
      state.copyWith(settings: sanitized, isSaving: true, clearFeedback: true),
    );
    await _settingsRepo.saveSettings(sanitized);
    await _coordinator.refreshIfPermitted(forceReschedule: true);
    if (isClosed) return;
    emit(state.copyWith(isSaving: false, settings: sanitized));
  }

  Future<bool> sendTestNotification({
    required String title,
    required String body,
  }) async {
    return _service.showTestNotification(title: title, body: body);
  }
}
