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
import 'package:business_manager/core/di/register_module.dart' as _i453;
import 'package:business_manager/core/localization/locale_cubit.dart' as _i588;
import 'package:business_manager/core/theme/theme_cubit.dart' as _i772;
import 'package:business_manager/core/utils/id_generator.dart' as _i656;
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
    gh.lazySingleton<_i790.AppLogger>(
      () => _i790.AppLogger(gh<_i516.AppConfig>()),
    );
    gh.lazySingleton<_i588.LocaleCubit>(
      () => _i588.LocaleCubit(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i772.ThemeCubit>(
      () => _i772.ThemeCubit(gh<_i460.SharedPreferences>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i453.RegisterModule {}
