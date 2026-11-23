import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/di/injection.config.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: false,
  asExtension: true,
  ignoreUnregisteredTypes: [AppConfig],
)
Future<void> configureDependencies(AppConfig config) async {
  if (!getIt.isRegistered<AppConfig>()) {
    getIt.registerSingleton<AppConfig>(config);
  }
  await getIt.init();
}
