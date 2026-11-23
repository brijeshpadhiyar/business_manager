import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Standard page scaffold applying consistent AppBar height (`56dp`),
/// horizontal padding (`16dp` optional), and max content width on wide screens.
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

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              toolbarHeight: AppSizing.appBarHeight,
              leading: leading,
              title: titleWidget ?? (title != null ? Text(title!) : null),
              actions: actions,
            )
          : null,
      body: SafeArea(child: content),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
