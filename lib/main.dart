import 'package:business_manager/bootstrap.dart';
import 'package:business_manager/core/config/app_config.dart';

/// Default entrypoint delegating to environment-configured flavor
/// (defaults to `dev` when launched without `--dart-define-from-file`).
Future<void> main() async {
  await bootstrap(AppConfig.fromEnvironment());
}
