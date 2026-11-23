import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/app_router.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
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
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(widget.config);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocaleCubit>.value(value: getIt<LocaleCubit>()),
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp.router(
                debugShowCheckedModeBanner: widget.config.isDev,
                onGenerateTitle: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return widget.config.isDev ? l10n.appTitleDev : l10n.appTitle;
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
              );
            },
          );
        },
      ),
    );
  }
}
