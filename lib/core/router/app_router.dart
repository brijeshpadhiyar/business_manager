import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/design_system_showcase_page.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(AppConfig config) {
  return GoRouter(
    initialLocation: RoutePaths.showcase,
    routes: [
      GoRoute(
        path: RoutePaths.showcase,
        builder: (context, state) => DesignSystemShowcasePage(config: config),
      ),
    ],
  );
}
