import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:material_ui/material_ui.dart';

/// The app's list row. Wraps [ListTile] with the app radius and text styles.
///
/// Use [AppListTile.text] for the common "title + optional subtitle" case.
final class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.selected = false,
    this.enabled = true,
    this.contentPadding,
    this.isThreeLine = false,
  });

  /// Convenience constructor taking plain strings.
  AppListTile.text({
    super.key,
    required String title,
    String? subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.dense = false,
    this.selected = false,
    this.enabled = true,
    this.contentPadding,
    this.isThreeLine = false,
  }) : title = Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
       subtitle = subtitle == null
           ? null
           : Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis);

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool dense;
  final bool selected;
  final bool enabled;
  final EdgeInsetsGeometry? contentPadding;
  final bool isThreeLine;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      dense: dense,
      selected: selected,
      enabled: enabled,
      contentPadding: contentPadding,
      isThreeLine: isThreeLine,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    );
  }
}
