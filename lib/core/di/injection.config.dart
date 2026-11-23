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
import 'package:business_manager/core/theme/theme_cubit.dart' as _i772;
import 'package:business_manager/core/utils/id_generator.dart' as _i656;
import 'package:business_manager/features/business_profile/data/repositories/business_profile_repository_impl.dart'
    as _i930;
import 'package:business_manager/features/business_profile/domain/repositories/business_profile_repository.dart'
    as _i521;
import 'package:business_manager/features/business_profile/presentation/bloc/business_profile_cubit.dart'
    as _i1018;
import 'package:business_manager/features/inventory/presentation/bloc/inventory_overview_cubit.dart'
    as _i931;
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart'
    as _i1010;
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart'
    as _i932;
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart'
    as _i309;
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart'
    as _i548;
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart'
    as _i658;
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart'
    as _i926;
import 'package:business_manager/features/processes/presentation/bloc/process_detail_cubit.dart'
    as _i515;
import 'package:business_manager/features/processes/presentation/bloc/process_list_cubit.dart'
    as _i531;
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart'
    as _i610;
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart'
    as _i307;
import 'package:business_manager/features/rates/presentation/bloc/rate_history_cubit.dart'
    as _i576;
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart'
    as _i966;
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart'
    as _i291;
import 'package:business_manager/features/workers/presentation/bloc/worker_assignments_cubit.dart'
    as _i560;
import 'package:business_manager/features/workers/presentation/bloc/worker_detail_cubit.dart'
    as _i506;
import 'package:business_manager/features/workers/presentation/bloc/worker_list_cubit.dart'
    as _i249;
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
    gh.lazySingleton<_i177.AppDatabase>(
      () => registerModule.appDatabase(gh<_i516.AppConfig>()),
      dispose: _i453.disposeAppDatabase,
    );
    gh.lazySingleton<_i790.AppLogger>(
      () => _i790.AppLogger(gh<_i516.AppConfig>()),
    );
    gh.lazySingleton<_i588.LocaleCubit>(
      () => _i588.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i772.ThemeCubit>(
      () => _i772.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i586.MediaStorageService>(
      () => registerModule.mediaStorageService(
        gh<_i516.AppConfig>(),
        gh<_i656.IdGenerator>(),
      ),
    );
    gh.lazySingleton<_i665.DatabaseTransactionRunner>(
      () => _i665.DatabaseTransactionRunner(gh<_i177.AppDatabase>()),
    );
    gh.lazySingleton<_i934.DatabaseInitializer>(
      () => _i934.DatabaseInitializer(
        gh<_i177.AppDatabase>(),
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
    gh.factory<_i309.LotDetailCubit>(
      () => _i309.LotDetailCubit(gh<_i932.LotRepository>()),
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
    gh.lazySingleton<_i307.RateRepository>(
      () => _i610.RateRepositoryImpl(
        gh<_i177.AppDatabase>(),
        gh<_i665.DatabaseTransactionRunner>(),
        gh<_i656.IdGenerator>(),
      ),
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
    gh.factory<_i576.RateHistoryCubit>(
      () => _i576.RateHistoryCubit(
        gh<_i291.WorkerRepository>(),
        gh<_i926.ProcessRepository>(),
        gh<_i307.RateRepository>(),
      ),
    );
    gh.factory<_i506.WorkerDetailCubit>(
      () => _i506.WorkerDetailCubit(gh<_i291.WorkerRepository>()),
    );
    gh.factory<_i249.WorkerListCubit>(
      () => _i249.WorkerListCubit(gh<_i291.WorkerRepository>()),
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
    return this;
  }
}

class _$RegisterModule extends _i453.RegisterModule {}
