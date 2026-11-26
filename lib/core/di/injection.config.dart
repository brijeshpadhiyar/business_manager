// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:business_manager/core/config/app_config.dart' as _i516;
import 'package:business_manager/core/config/app_logger.dart' as _i790;
import 'package:business_manager/core/database/app_database.dart' as _i177;
import 'package:business_manager/core/database/database_initializer.dart'
    as _i934;
import 'package:business_manager/core/database/database_transaction_runner.dart'
    as _i665;
import 'package:business_manager/core/di/register_module.dart' as _i453;
import 'package:business_manager/core/localization/locale_cubit.dart' as _i588;
import 'package:business_manager/core/platform/media_storage_service.dart'
    as _i586;
import 'package:business_manager/core/services/form_draft_service.dart'
    as _i1031;
import 'package:business_manager/core/theme/density_cubit.dart' as _i520;
import 'package:business_manager/core/theme/theme_cubit.dart' as _i772;
import 'package:business_manager/core/utils/id_generator.dart' as _i656;
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart'
    as _i134;
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart'
    as _i762;
import 'package:business_manager/features/accounting/presentation/bloc/accounting_overview_cubit.dart'
    as _i1023;
import 'package:business_manager/features/accounting/presentation/bloc/worker_ledger_cubit.dart'
    as _i711;
import 'package:business_manager/features/auth/data/repositories/supabase_auth_repository.dart'
    as _i475;
import 'package:business_manager/features/auth/data/repositories/supabase_team_repository.dart'
    as _i249;
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart'
    as _i941;
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart'
    as _i154;
import 'package:business_manager/features/backup/data/services/data_health_service.dart'
    as _i125;
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart'
    as _i744;
import 'package:business_manager/features/backup/presentation/bloc/backup_restore_cubit.dart'
    as _i74;
import 'package:business_manager/features/backup/presentation/bloc/data_health_cubit.dart'
    as _i478;
import 'package:business_manager/features/business_profile/data/repositories/business_profile_repository_impl.dart'
    as _i930;
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart'
    as _i521;
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_cubit.dart'
    as _i1018;
import 'package:business_manager/features/dashboard/presentation/bloc/dashboard_cubit.dart'
    as _i736;
import 'package:business_manager/features/guidance/data/repositories/shared_prefs_guide_repository.dart'
    as _i97;
import 'package:business_manager/features/guidance/data/services/flutter_tts_guide_voice_service.dart'
    as _i69;
import 'package:business_manager/features/guidance/domain/repositories/guide_preferences_repository.dart'
    as _i339;
import 'package:business_manager/features/guidance/domain/services/guide_voice_service.dart'
    as _i398;
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart'
    as _i1048;
import 'package:business_manager/features/inventory/presentation/bloc/inventory_overview_cubit.dart'
    as _i931;
import 'package:business_manager/features/lots/data/repositories/colour_master_repository_impl.dart'
    as _i1065;
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart'
    as _i1010;
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart'
    as _i315;
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart'
    as _i932;
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart'
    as _i309;
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart'
    as _i548;
import 'package:business_manager/features/notifications/data/repositories/notification_settings_repository.dart'
    as _i837;
import 'package:business_manager/features/notifications/data/services/flutter_local_notifications_adapter.dart'
    as _i925;
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart'
    as _i754;
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart'
    as _i105;
import 'package:business_manager/features/notifications/presentation/bloc/notification_settings_cubit.dart'
    as _i245;
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart'
    as _i877;
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart'
    as _i1058;
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart'
    as _i685;
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart'
    as _i658;
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart'
    as _i926;
import 'package:business_manager/features/processes/presentation/bloc/process_detail_cubit.dart'
    as _i515;
import 'package:business_manager/features/processes/presentation/bloc/process_list_cubit.dart'
    as _i531;
import 'package:business_manager/features/production_history/data/repositories/production_history_repository_impl.dart'
    as _i25;
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart'
    as _i995;
import 'package:business_manager/features/production_history/presentation/bloc/inspection_queue_cubit.dart'
    as _i510;
import 'package:business_manager/features/production_history/presentation/bloc/lot_history_cubit.dart'
    as _i789;
import 'package:business_manager/features/production_history/presentation/bloc/process_history_cubit.dart'
    as _i937;
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart'
    as _i232;
import 'package:business_manager/features/production_history/presentation/bloc/transaction_detail_cubit.dart'
    as _i152;
import 'package:business_manager/features/production_history/presentation/bloc/worker_production_history_cubit.dart'
    as _i1049;
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart'
    as _i610;
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart'
    as _i307;
import 'package:business_manager/features/rates/presentation/bloc/rate_history_cubit.dart'
    as _i576;
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart'
    as _i546;
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart'
    as _i17;
import 'package:business_manager/features/reports/data/services/excel_csv_export_service.dart'
    as _i335;
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart'
    as _i617;
import 'package:business_manager/features/reports/domain/services/report_export_service.dart'
    as _i647;
import 'package:business_manager/features/reports/presentation/bloc/daily_summary_cubit.dart'
    as _i198;
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart'
    as _i507;
import 'package:business_manager/features/security/data/repositories/secure_storage_security_repository.dart'
    as _i933;
import 'package:business_manager/features/security/data/services/local_auth_biometric_service.dart'
    as _i19;
import 'package:business_manager/features/security/data/services/window_security_channel.dart'
    as _i128;
import 'package:business_manager/features/security/domain/repositories/security_repository.dart'
    as _i391;
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart'
    as _i263;
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart'
    as _i945;
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart'
    as _i306;
import 'package:business_manager/features/stock_movements/presentation/bloc/stock_movements_cubit.dart'
    as _i971;
import 'package:business_manager/features/sync/data/services/supabase_cloud_sync_gateway.dart'
    as _i860;
import 'package:business_manager/features/sync/data/services/sync_conflict_service.dart'
    as _i649;
import 'package:business_manager/features/sync/data/services/sync_engine.dart'
    as _i605;
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart'
    as _i1043;
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart'
    as _i570;
import 'package:business_manager/features/team/domain/repositories/team_repository.dart'
    as _i1067;
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart'
    as _i966;
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart'
    as _i291;
import 'package:business_manager/features/workers/presentation/bloc/worker_assignments_cubit.dart'
    as _i560;
import 'package:business_manager/features/workers/presentation/bloc/worker_detail_cubit.dart'
    as _i506;
import 'package:business_manager/features/workers/presentation/bloc/worker_list_cubit.dart'
    as _i250;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i656.IdGenerator>(() => _i656.IdGenerator());
    gh.lazySingleton<_i17.AndroidReportPrintChannel>(
      () => _i17.AndroidReportPrintChannel(),
    );
    gh.lazySingleton<_i177.AppDatabase>(
      () => registerModule.appDatabase(gh<_i516.AppConfig>()),
      dispose: _i453.disposeAppDatabase,
    );
    gh.lazySingleton<_i398.GuideVoiceService>(
      () => _i69.FlutterTtsGuideVoiceService(),
    );
    gh.lazySingleton<_i790.AppLogger>(
      () => _i790.AppLogger(gh<_i516.AppConfig>()),
    );
    gh.lazySingleton<_i837.NotificationSettingsRepository>(
      () => _i837.NotificationSettingsRepository(gh<_i516.AppConfig>()),
    );
    gh.lazySingleton<_i649.SyncConflictService>(
      () => _i649.SyncConflictService(
        gh<_i177.AppDatabase>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i941.AuthRepository>(
      () => _i475.SupabaseAuthRepository(
        gh<_i516.AppConfig>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i391.WindowSecurityService>(
      () => _i128.MethodChannelWindowSecurityService(),
    );
    gh.lazySingleton<_i391.BiometricAuthService>(
      () => _i19.LocalAuthBiometricService(),
    );
    gh.lazySingleton<_i391.SecurityRepository>(
      () => _i933.SecureStorageSecurityRepository(
        gh<_i516.AppConfig>(),
        gh<_i177.AppDatabase>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i588.LocaleCubit>(
      () => _i588.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1031.FormDraftService>(
      () => _i1031.FormDraftService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i520.DensityCubit>(
      () => _i520.DensityCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i772.ThemeCubit>(
      () => _i772.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i1067.TeamRepository>(
      () => _i249.SupabaseTeamRepository(
        gh<_i516.AppConfig>(),
        gh<_i177.AppDatabase>(),
        gh<_i656.IdGenerator>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i586.MediaStorageService>(
      () => registerModule.mediaStorageService(
        gh<_i516.AppConfig>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i744.BackupRestoreService>(
      () => registerModule.backupRestoreService(
        gh<_i177.AppDatabase>(),
        gh<_i516.AppConfig>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i665.DatabaseTransactionRunner>(
      () => _i665.DatabaseTransactionRunner(gh<_i177.AppDatabase>()),
    );
    gh.lazySingleton<_i125.DataHealthService>(
      () => _i125.DataHealthService(
        gh<_i177.AppDatabase>(),
        gh<_i586.MediaStorageService>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i263.AppLockCubit>(
      () => _i263.AppLockCubit(
        gh<_i391.SecurityRepository>(),
        gh<_i391.BiometricAuthService>(),
        gh<_i391.WindowSecurityService>(),
      ),
    );
    gh.lazySingleton<_i762.AccountingRepository>(
      () => _i134.AccountingRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i105.LocalNotificationService>(
      () => _i925.FlutterLocalNotificationsAdapter(
        gh<_i837.NotificationSettingsRepository>(),
      ),
    );
    gh.lazySingleton<_i339.GuidePreferencesRepository>(
      () => _i97.SharedPrefsGuideRepository(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i934.DatabaseInitializer>(
      () => _i934.DatabaseInitializer(
        gh<_i177.AppDatabase>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i1043.CloudSyncGateway>(
      () => _i860.SupabaseCloudSyncGateway(
        gh<_i516.AppConfig>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.factory<_i74.BackupRestoreCubit>(
      () => _i74.BackupRestoreCubit(
        gh<_i744.BackupRestoreService>(),
        gh<_i516.AppConfig>(),
      ),
    );
    gh.lazySingleton<_i154.AuthCubit>(
      () =>
          _i154.AuthCubit(gh<_i941.AuthRepository>(), gh<_i177.AppDatabase>()),
    );
    gh.lazySingleton<_i605.SyncEngine>(
      () => _i605.SyncEngine(
        gh<_i177.AppDatabase>(),
        gh<_i1043.CloudSyncGateway>(),
        gh<_i586.MediaStorageService>(),
        gh<_i941.AuthRepository>(),
        gh<_i656.IdGenerator>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.lazySingleton<_i932.LotRepository>(
      () => _i1010.LotRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
        gh<_i586.MediaStorageService>(),
      ),
    );
    gh.factory<_i478.DataHealthCubit>(
      () => _i478.DataHealthCubit(gh<_i125.DataHealthService>()),
    );
    gh.factory<_i548.LotListCubit>(
      () => _i548.LotListCubit(gh<_i932.LotRepository>()),
    );
    gh.lazySingleton<_i291.WorkerRepository>(
      () => _i966.WorkerRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i647.ReportExportService>(
      () => _i335.ExcelCsvExportService(
        gh<_i17.AndroidReportPrintChannel>(),
        gh<_i263.AppLockCubit>(),
      ),
    );
    gh.lazySingleton<_i307.RateRepository>(
      () => _i610.RateRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i1048.GuideCubit>(
      () => _i1048.GuideCubit(
        gh<_i339.GuidePreferencesRepository>(),
        gh<_i398.GuideVoiceService>(),
      ),
    );
    gh.lazySingleton<_i995.ProductionHistoryRepository>(
      () => _i25.ProductionHistoryRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i315.ColourMasterRepository>(
      () => _i1065.ColourMasterRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.factory<_i1023.AccountingOverviewCubit>(
      () => _i1023.AccountingOverviewCubit(gh<_i762.AccountingRepository>()),
    );
    gh.factory<_i711.WorkerLedgerCubit>(
      () => _i711.WorkerLedgerCubit(gh<_i762.AccountingRepository>()),
    );
    gh.lazySingleton<_i926.ProcessRepository>(
      () => _i658.ProcessRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i521.BusinessProfileRepository>(
      () => _i930.BusinessProfileRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.factory<_i931.InventoryOverviewCubit>(
      () => _i931.InventoryOverviewCubit(gh<_i932.LotRepository>()),
    );
    gh.lazySingleton<_i306.StockMovementRepository>(
      () => _i945.StockMovementRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i570.SyncCubit>(
      () => _i570.SyncCubit(
        gh<_i177.AppDatabase>(),
        gh<_i605.SyncEngine>(),
        gh<_i1043.CloudSyncGateway>(),
        gh<_i154.AuthCubit>(),
        gh<_i790.AppLogger>(),
      ),
    );
    gh.factory<_i576.RateHistoryCubit>(
      () => _i576.RateHistoryCubit(
        gh<_i291.WorkerRepository>(),
        gh<_i926.ProcessRepository>(),
        gh<_i307.RateRepository>(),
      ),
    );
    gh.factory<_i250.WorkerListCubit>(
      () => _i250.WorkerListCubit(gh<_i291.WorkerRepository>()),
    );
    gh.factory<_i971.StockMovementsCubit>(
      () => _i971.StockMovementsCubit(gh<_i306.StockMovementRepository>()),
    );
    gh.factory<_i506.WorkerDetailCubit>(
      () => _i506.WorkerDetailCubit(
        gh<_i291.WorkerRepository>(),
        gh<_i762.AccountingRepository>(),
        gh<_i306.StockMovementRepository>(),
      ),
    );
    gh.factory<_i515.ProcessDetailCubit>(
      () => _i515.ProcessDetailCubit(gh<_i926.ProcessRepository>()),
    );
    gh.factory<_i531.ProcessListCubit>(
      () => _i531.ProcessListCubit(gh<_i926.ProcessRepository>()),
    );
    gh.factory<_i560.WorkerAssignmentsCubit>(
      () => _i560.WorkerAssignmentsCubit(
        gh<_i291.WorkerRepository>(),
        gh<_i926.ProcessRepository>(),
      ),
    );
    gh.factory<_i1018.BusinessProfileCubit>(
      () => _i1018.BusinessProfileCubit(gh<_i521.BusinessProfileRepository>()),
    );
    gh.lazySingleton<_i1058.ProcessRoutingRepository>(
      () => _i877.ProcessRoutingRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i306.StockMovementRepository>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i617.ReportsRepository>(
      () => _i546.ReportsRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i306.StockMovementRepository>(),
        gh<_i762.AccountingRepository>(),
      ),
    );
    gh.factory<_i510.InspectionQueueCubit>(
      () => _i510.InspectionQueueCubit(gh<_i995.ProductionHistoryRepository>()),
    );
    gh.factory<_i789.LotHistoryCubit>(
      () => _i789.LotHistoryCubit(gh<_i995.ProductionHistoryRepository>()),
    );
    gh.factory<_i937.ProcessHistoryCubit>(
      () => _i937.ProcessHistoryCubit(gh<_i995.ProductionHistoryRepository>()),
    );
    gh.factory<_i232.ProductionHistoryDashboardCubit>(
      () => _i232.ProductionHistoryDashboardCubit(
        gh<_i995.ProductionHistoryRepository>(),
      ),
    );
    gh.factory<_i152.TransactionDetailCubit>(
      () =>
          _i152.TransactionDetailCubit(gh<_i995.ProductionHistoryRepository>()),
    );
    gh.factory<_i1049.WorkerProductionHistoryCubit>(
      () => _i1049.WorkerProductionHistoryCubit(
        gh<_i995.ProductionHistoryRepository>(),
      ),
    );
    gh.factory<_i685.JobRoutingCubit>(
      () => _i685.JobRoutingCubit(
        gh<_i1058.ProcessRoutingRepository>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.factory<_i507.ReportsCubit>(
      () => _i507.ReportsCubit(
        gh<_i617.ReportsRepository>(),
        gh<_i647.ReportExportService>(),
      ),
    );
    gh.factory<_i309.LotDetailCubit>(
      () => _i309.LotDetailCubit(
        gh<_i932.LotRepository>(),
        gh<_i1058.ProcessRoutingRepository>(),
      ),
    );
    gh.lazySingleton<_i754.NotificationRefreshCoordinator>(
      () => _i754.NotificationRefreshCoordinator(
        gh<_i177.AppDatabase>(),
        gh<_i306.StockMovementRepository>(),
        gh<_i762.AccountingRepository>(),
        gh<_i617.ReportsRepository>(),
        gh<_i391.SecurityRepository>(),
        gh<_i588.LocaleCubit>(),
        gh<_i837.NotificationSettingsRepository>(),
        gh<_i105.LocalNotificationService>(),
      ),
    );
    gh.factory<_i245.NotificationSettingsCubit>(
      () => _i245.NotificationSettingsCubit(
        gh<_i837.NotificationSettingsRepository>(),
        gh<_i105.LocalNotificationService>(),
        gh<_i754.NotificationRefreshCoordinator>(),
      ),
    );
    gh.factory<_i736.DashboardCubit>(
      () => _i736.DashboardCubit(gh<_i617.ReportsRepository>()),
    );
    gh.factory<_i198.DailySummaryCubit>(
      () => _i198.DailySummaryCubit(gh<_i617.ReportsRepository>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i453.RegisterModule {}
