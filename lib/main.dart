import 'package:business_manager/bootstrap.dart';
import 'package:business_manager/core/config/app_config.dart';

/// Default entrypoint. The flavor comes from `APP_FLAVOR` in
/// `--dart-define-from-file`; startup fails if it is missing.
Future<void> main() async {
  await bootstrap(AppConfig.fromEnvironment());
}
