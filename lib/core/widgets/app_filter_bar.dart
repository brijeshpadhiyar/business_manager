import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Standardized responsive filter toolbar combining a search field, optional
/// filter chips/dropdowns, and optional trailing actions without horizontal
/// overflow across `360dp`–`1920dp`.
final class AppFilterBar extends StatelessWidget {
  const AppFilterBar({
    super.key,
    this.searchField,
    this.filters = const [],
    this.trailingActions = const [],
  });

  final Widget? searchField;
  final List<Widget> filters;
  final List<Widget> trailingActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.tabletMinWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (searchField != null || trailingActions.isNotEmpty)
              wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (searchField != null) Expanded(child: searchField!),
                        if (trailingActions.isNotEmpty) ...[
                          if (searchField != null)
                            const SizedBox(width: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: trailingActions,
                          ),
                        ],
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ?searchField,
                        if (trailingActions.isNotEmpty) ...[
                          if (searchField != null)
                            const SizedBox(height: AppSpacing.xs),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: trailingActions,
                          ),
                        ],
                      ],
                    ),
            if (filters.isNotEmpty) ...[
              if (searchField != null || trailingActions.isNotEmpty)
                const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: filters,
              ),
            ],
          ],
        );
      },
    );
  }
}
