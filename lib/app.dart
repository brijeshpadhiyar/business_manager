import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/app_session_controller.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/app_router.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/app_lock_gate.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class BusinessManagerApp extends StatefulWidget {
  const BusinessManagerApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<BusinessManagerApp> createState() => _BusinessManagerAppState();
}

final class _BusinessManagerAppState extends State<BusinessManagerApp> {
  late GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.config);
    AppSessionController.instance.addListener(_onSessionReloaded);
    final lockCubit = getIt<AppLockCubit>();
    if (lockCubit.state.status == AppLockStatus.initializing) {
      lockCubit.initialize();
    }
  }

  void _onSessionReloaded() {
    if (!mounted) return;
    final oldRouter = _router;
    setState(() {
      _router = createAppRouter(widget.config);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => oldRouter.dispose());
  }

  @override
  void dispose() {
    AppSessionController.instance.removeListener(_onSessionReloaded);
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionGen = AppSessionController.instance.generation;
    return KeyedSubtree(
      key: ValueKey<int>(sessionGen),
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
          BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
          BlocProvider<AppLockCubit>.value(value: getIt<AppLockCubit>()),
        ],
        child: BlocBuilder<LocaleCubit, LocaleState>(
          builder: (context, localeState) {
            return BlocBuilder<ThemeCubit, ThemeState>(
              builder: (context, themeState) {
                return MaterialApp.router(
                  debugShowCheckedModeBanner: widget.config.isDev,
                  onGenerateTitle: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return widget.config.isDev
                        ? l10n.appTitleDev
                        : l10n.appTitle;
                  },
                  locale: localeState.preference.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    ...GlobalMaterialLocalizations.delegates,
                  ],
                  themeMode: themeState.preference.themeMode,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  routerConfig: _router,
                  builder: (context, child) => AppLockGate(
                    onNavigateDeepLink: (routePath) => _router.push(routePath),
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
