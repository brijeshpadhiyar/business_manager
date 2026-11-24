import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:material_ui/material_ui.dart';

/// Standard StitchFlow V1.3 page scaffold with a layered glassmorphism ambient
/// backdrop, frosted glass AppBar (`56dp`), horizontal padding, and max content
/// width on wide screens.
final class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = AppSpacing.screenAll,
    this.constrainMaxWidth = true,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry? padding;
  final bool constrainMaxWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;

    Widget content = body;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (constrainMaxWidth) {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.maxContentWidth,
          ),
          child: content,
        ),
      );
    }

    final showAppBar = title != null || titleWidget != null || actions != null;

    return AppGlassBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: showAppBar
            ? AppBar(
                toolbarHeight: AppSizing.appBarHeight,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: leading,
                title: titleWidget ?? (title != null ? Text(title!) : null),
                actions: actions,
                flexibleSpace: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.navGlassFill,
                        border: Border(
                          bottom: BorderSide(
                            color: tokens.navGlassBorder,
                            width: 0.9,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
        body: SafeArea(child: content),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
