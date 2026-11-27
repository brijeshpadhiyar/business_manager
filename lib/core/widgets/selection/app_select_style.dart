import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/app_loader.dart';
import 'package:business_manager/core/widgets/app_text.dart';
import 'package:business_manager/core/widgets/selection/app_select_types.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:material_ui/material_ui.dart';

/// Internal bridge between the app design system and `dropdown_search`.
///
/// This is the ONLY place (together with `app_select.dart` and
/// `app_multi_select.dart`) allowed to import `dropdown_search`. Feature code
/// must use [AppSelect] / [AppMultiSelect].
abstract final class AppSelectStyle {
  /// Default async page size.
  static const int defaultPageSize = 30;

  /// Debounce applied to search typing before the loader / filter runs.
  static const Duration searchDelay = Duration(milliseconds: 300);

  /// Resolves [AppSelectPresentation.auto] against the current window width.
  static AppSelectPresentation resolve(
    BuildContext context,
    AppSelectPresentation presentation,
  ) {
    if (presentation != AppSelectPresentation.auto) return presentation;
    final width = MediaQuery.sizeOf(context).width;
    return AppBreakpoints.fromWidth(width).isCompact
        ? AppSelectPresentation.bottomSheet
        : AppSelectPresentation.menu;
  }

  static double sheetMaxHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.8;

  static InputDecoration fieldDecoration({
    required String label,
    String? hint,
    String? errorText,
    required bool enabled,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      enabled: enabled,
    );
  }

  static TextFieldProps searchField(BuildContext context) {
    return TextFieldProps(
      autofocus: true,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.selectSearchHint,
        prefixIcon: const Icon(AppIcons.search, size: AppSizing.iconMd),
        isDense: true,
      ),
    );
  }

  static MenuProps menu(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MenuProps(
      backgroundColor: scheme.surfaceContainer,
      elevation: 3,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(top: AppSpacing.xs),
    );
  }

  static ModalBottomSheetProps sheet(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ModalBottomSheetProps(
      backgroundColor: scheme.surfaceContainerLow,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
    );
  }

  static DialogProps dialog(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DialogProps(
      backgroundColor: scheme.surfaceContainerLow,
      barrierDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlBorder),
      clipBehavior: Clip.antiAlias,
    );
  }

  static BoxConstraints constraintsFor(
    BuildContext context,
    AppSelectPresentation resolved,
  ) {
    return switch (resolved) {
      AppSelectPresentation.menu => const BoxConstraints(maxHeight: 360),
      AppSelectPresentation.dialog => const BoxConstraints(
        maxHeight: 520,
        maxWidth: AppSizing.maxDialogWidth,
      ),
      _ => BoxConstraints(maxHeight: sheetMaxHeight(context)),
    };
  }

  static Widget? title(String label, AppSelectPresentation resolved) {
    if (resolved == AppSelectPresentation.menu) return null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: AppText(label, variant: AppTextVariant.label),
    );
  }

  static Widget empty(BuildContext context, String _) =>
      _Message(icon: AppIcons.search, text: context.l10n.selectNoResults);

  static Widget error(BuildContext context, String _, Object? _) =>
      _Message(icon: AppIcons.error, text: context.l10n.selectLoadError);

  static Widget loading(BuildContext context, String _) => const Padding(
    padding: EdgeInsets.all(AppSpacing.xl),
    child: Center(child: AppSpinner(size: 28)),
  );

  static InfiniteScrollProps infiniteScroll(int pageSize) =>
      InfiniteScrollProps(
        loadProps: LoadProps(take: pageSize),
        loadingMoreBuilder: (context, _) => const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: AppSpinner(size: 20)),
        ),
      );

  /// Popup row: title, optional subtitle/leading, check mark when selected.
  static Widget item<T>({
    required BuildContext context,
    required T item,
    required bool isDisabled,
    required bool isSelected,
    required String Function(T) labelOf,
    String? Function(T)? subtitleOf,
    Widget? Function(T)? leadingOf,
    bool showCheck = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = subtitleOf?.call(item);
    final leading = leadingOf?.call(item);
    final color = isDisabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (isSelected ? scheme.primary : scheme.onSurface);

    return Semantics(
      selected: isSelected,
      enabled: !isDisabled,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizing.touchTargetMin),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        color: isSelected
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : null,
        child: Row(
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labelOf(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: isSelected ? FontWeight.w600 : null,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (showCheck && isSelected)
              Icon(AppIcons.confirm, size: AppSizing.iconMd, color: color),
          ],
        ),
      ),
    );
  }

  /// Case-insensitive "contains" filter on the label (and subtitle).
  static bool matches<T>(
    T item,
    String filter,
    String Function(T) labelOf,
    String? Function(T)? subtitleOf,
  ) {
    final q = filter.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (labelOf(item).toLowerCase().contains(q)) return true;
    final sub = subtitleOf?.call(item);
    return sub != null && sub.toLowerCase().contains(q);
  }
}

final class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppSizing.iconLg),
          const SizedBox(height: AppSpacing.sm),
          AppText(text, textAlign: TextAlign.center, color: color),
        ],
      ),
    );
  }
}
