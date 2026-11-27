/// StitchFlow shared widgets. Screens should build from these, not raw
/// Material widgets, so every page looks and behaves the same.
///
/// State rules for every screen:
/// * **Loading** — lists, tables and dashboards use [AppSkeletonList] /
///   [AppSkeletonBox] (the shape of the content); forms, detail pages and
///   short waits use [AppLoader].
/// * **Load failed** — [AppErrorView] with a retry action. It turns domain
///   codes and exception dumps into localized text by itself.
/// * **Action failed** (save, delete, export) — `AppFeedback.showError`,
///   which also sanitizes the message. In catch blocks, pass
///   `ValidationLocalizer.describeError(l10n, e)`, never `e.toString()`.
/// * **Nothing to show** — [AppEmptyState] with a next-step action.
/// * **Choosing from records** (workers, lots, processes, colours) —
///   [AppSelect] / [AppMultiSelect] (searchable); [AppDropdown] is for short
///   fixed lists such as enums and statuses.
library;

export '../design_system/app_breakpoints.dart';
export 'app_action_row.dart';
export 'app_adaptive_field.dart';
export 'app_animated_number.dart';
export 'app_avatar.dart';
export 'app_bottom_sheet.dart';
export 'app_breadcrumb_bar.dart';
export 'app_button.dart';
export 'app_card.dart';
export 'app_checkbox.dart';
export 'app_chip.dart';
export 'app_collapsible_filters.dart';
export 'app_collapsible_header.dart';
export 'app_colour_swatch.dart';
export 'app_data_table.dart';
export 'app_dialog.dart';
export 'app_divider.dart';
export 'app_dropdown.dart';
export 'app_empty_state.dart';
export 'app_error_view.dart';
export 'app_feedback.dart';
export 'app_form_dirty_tracker.dart';
export 'app_form_section.dart';
export 'app_glass_backdrop.dart';
export 'app_glass_surface.dart';
export 'app_heading.dart';
export 'app_icon_button.dart';
export 'app_icon_pop.dart';
export 'app_lazy_section.dart';
export 'app_list_tile.dart';
export 'app_loader.dart';
export 'app_metric_tile.dart';
export 'app_progress_bar.dart';
export 'app_radio.dart';
export 'app_scaffold.dart';
export 'app_search_field.dart';
export 'app_skeleton.dart';
export 'app_status_badge.dart';
export 'app_switch.dart';
export 'app_text.dart';
export 'app_text_field.dart';
export 'app_unsaved_changes_guard.dart';
export 'date_time/app_date_picker.dart';
export 'date_time/app_date_range_picker.dart';
export 'date_time/app_date_time_dialogs.dart';
export 'date_time/app_multi_date_picker.dart';
export 'date_time/app_picker_field.dart';
export 'date_time/app_time_picker.dart';
export 'responsive_navigation.dart';
export 'selection/app_multi_select.dart';
export 'selection/app_select.dart';
export 'selection/app_select_types.dart';
