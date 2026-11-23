import 'package:business_manager/bootstrap.dart';
import 'package:business_manager/core/config/app_config.dart';

Future<void> main() async {
  await bootstrap(AppConfig.dev());
}
