# StitchFlow — Complete Screen & Component Audit

**Audit Date:** 2026-11-24  
**Scope:** Complete inventory of all 45 existing screens, navigation destinations, dialogs/sheets, settings pages, and 32 reusable core widgets in `c:\A1\business_manager`.

---

## 1. Executive Summary

| Metric | Current Baseline | Target Maturity |
|---|---:|---|
| Feature Pages Inventoried | 45 | 46 (+ unified Designs & Colours view) |
| Core Reusable Widgets (`lib/core/widgets/`) | 32 | 35 (+ BreadcrumbBar, FormSection, FilterBar) |
| Pages using `AppDataTable` on Tablet/Desktop | 3 / 45 (6.7%) | All major operational list/ledger/history/report tables |
| Pages with explicit `Semantics` annotations | 0 / 45 (0%) | Core interactive controls, KPIs, badges, swatches & forms |
| Pages preserving Desktop Sidebar across navigation | 5 root tabs only (`/`) | All 46 pages via persistent GoRouter `ShellRoute` |
| Unconditional `dart:io`/`dart:isolate` Web Blockers | 7 files | 0 (100% platform-conditional Web + Native support) |

---

## 2. Complete Screen Inventory (45 Existing Pages)

### 2.1 Dashboard & Navigation Shell
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Responsive Shell | `lib/core/router/app_router.dart` (`StitchFlowShellPage`) | 608 | Shell | N/A | N/A | Only wraps `/`; secondary routes drop sidebar & break browser refresh URLs. Upgrade to GoRouter `ShellRoute` with real tab URLs (`/`, `/lots`, `/stock`, `/workers`, `/settings`) + desktop breadcrumbs. |
| Dashboard | `lib/features/dashboard/presentation/pages/dashboard_page.dart` | 987 | Raw scroll | No | Skel only | Uses raw scroll layout instead of `AppContentWidth.wide`; improve multi-column tablet/desktop grid, surface Pending QC alerts cleanly, add Semantics & error retry state. |

### 2.2 Lots, Designs & Colours
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Lot List | `lib/features/lots/presentation/pages/lot_list_page.dart` | 283 | Collapsible | No | Empty + Err | Add `AppContentWidth.wide`, paginated/sortable `AppDataTable` on Tablet/Desktop, status filter chips, and direct button to **Designs & Colours** catalog. |
| Lot Create | `lib/features/lots/presentation/pages/lot_create_page.dart` | 1309 | Standard | No | Inline | Organize into responsive `AppFormSection` blocks (1-col mobile, 2-col desktop), add clear required markers & duplicate-submit guard, streamline multi-colour & multi-process setup. |
| Lot Detail | `lib/features/lots/presentation/pages/lot_detail_page.dart` | 1591 | Standard | No | Empty + Err | Use `AppContentWidth.standard`, refine action bar & cross-links (Routing, History, Timeline, Designs/Colours edit), improve tablet/desktop two-column summary layout. |
| Lot Colour Detail | `lib/features/lots/presentation/pages/lot_colour_detail_page.dart` | 770 | Standard | No | Full | Ensure clean historical unit price display, editability without mutating historical movement snapshots, and direct jump to issue/history. |
| **Designs & Colours** *(Gap)* | `lib/features/lots/presentation/pages/designs_colours_page.dart` *(New)* | — | Collapsible | Yes | Full | **Identified gap:** `colour_master`, `lot_designs`, and `design_colours` had no cross-lot management view. Adding unified catalog using existing tables only. |

### 2.3 Processes & Multi-Process Routing
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Process List | `lib/features/processes/presentation/pages/process_list_page.dart` | 260 | Collapsible | No | Empty + Err | Add wide responsive `AppDataTable` with search, active/inactive filter, and quick access to Process History. |
| Process Detail | `lib/features/processes/presentation/pages/process_detail_page.dart` | 565 | Standard | No | Err only | Add empty states for worker/lot/date/pending sub-tabs and responsive wide table layout. |
| Process Form | `lib/features/processes/presentation/pages/process_form_page.dart` | 383 | Standard | No | Err only | Use `AppContentWidth.narrow`, `AppFormSection`, clear retired-rule indicator for legacy `includeDamagedInLabour`. |
| Job Process Routing | `lib/features/process_routing/presentation/pages/job_process_routing_page.dart` | 1852 | Standard | No | Full | Use `AppContentWidth.wide`, make multi-process addition and ordering clearer on tablet/desktop. |

### 2.4 Workers & Rates
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Worker List | `lib/features/workers/presentation/pages/worker_list_page.dart` | 275 | Collapsible | No | Empty + Err | Add `AppContentWidth.wide`, paginated/sortable `AppDataTable` on Tablet/Desktop, status filter & quick actions (Ledger, History, Pay). |
| Worker Detail | `lib/features/workers/presentation/pages/worker_detail_page.dart` | 832 | Standard | No | Err only | Add empty state when no assignments yet, responsive 2-column summary on desktop, clear cross-links to Ledger, Rates, and Production History. |
| Worker Form | `lib/features/workers/presentation/pages/worker_form_page.dart` | 606 | Standard | No | Err only | Use `AppContentWidth.narrow`, `AppFormSection`, required indicators, double-submit guard. |
| Worker Assignments | `lib/features/workers/presentation/pages/worker_assignments_page.dart` | 378 | Standard | No | Empty + Err | Improve multi-process assignment clarity with clear rate status badges and skeleton loading. |
| Rate History | `lib/features/rates/presentation/pages/rate_history_page.dart` | 251 | Standard | No | Empty + Err | Render paginated/sortable `AppDataTable` on Tablet/Desktop highlighting active vs historical locked rates. |
| Rate Form | `lib/features/rates/presentation/pages/rate_form_page.dart` | 409 | Standard | No | Err only | Use `AppContentWidth.narrow`, clarify effective-date snapshot rule (historical work unaffected). |

### 2.5 Stock Movements, Returns & Quality Inspection
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Stock Movements | `lib/features/stock_movements/presentation/pages/stock_movements_page.dart` | 1113 | Standard | Yes | Full | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable` and `AppFilterBar`. |
| Stock Issue | `lib/features/stock_movements/presentation/pages/stock_issue_page.dart` | 1600 | Standard | No | Full | Use `AppContentWidth.standard` with responsive form sections and clear rate-lock preview. |
| Receive Return Picker | `lib/features/stock_movements/presentation/pages/receive_return_picker_page.dart` | 443 | Standard | No | Full | Upgrade to `AppContentWidth.wide` + paginated `AppDataTable` showing Assigned, Returned, Pending QC, and Outstanding. |
| Stock Settlement (Return) | `lib/features/stock_movements/presentation/pages/stock_settlement_page.dart` | 1219 | Standard | No | Err + Skel | Highlight 2-stage flow (Log Pending QC vs Inspect Immediately), quantity reconciliation strip, duplicate-submit lock. |
| Damaged Repair | `lib/features/stock_movements/presentation/pages/damaged_repair_page.dart` | 279 | Standard | No | Empty only | Add `AppErrorView` retry, link clearly to Inspection Queue for Schema v8 rejection repair & re-approval. |

### 2.6 Worker Accounting & Ledger
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Accounting Overview | `lib/features/accounting/presentation/pages/accounting_overview_page.dart` | 610 | Collapsible | No | Empty + Err | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable` for worker balances (Earned, Paid, Advance, Outstanding). |
| Worker Ledger | `lib/features/accounting/presentation/pages/worker_ledger_page.dart` | 660 | Standard | No | Full | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable` on Tablet/Desktop preserving tap-to-inspect transaction drill-down. |
| Payment Form | `lib/features/accounting/presentation/pages/payment_form_page.dart` | 331 | Standard | No | Empty only | Use `AppContentWidth.narrow`, clear Regular / Advance / Advance Refund selection with live balance preview & error handling. |
| Worker Adjustment Form | `lib/features/accounting/presentation/pages/worker_adjustment_form_page.dart` | 242 | Standard | No | Inline | Use `AppContentWidth.narrow`, clear credit/debit explanation and required reason. |

### 2.7 Production History & QC Inspection (Schema v8 — 7 Pages)
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Production History Dashboard | `lib/features/production_history/presentation/pages/production_history_dashboard_page.dart` | 536 | Standard | No | Full | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable` on Tablet/Desktop + `AppFilterBar`. |
| Lot History | `lib/features/production_history/presentation/pages/lot_history_page.dart` | 476 | Standard | No | Err + Skel | Add `AppContentWidth.wide`, responsive assignment table, empty state for unassigned lots, direct Lot/Worker/Process links. |
| Lot Timeline | `lib/features/production_history/presentation/pages/lot_timeline_page.dart` | 246 | Standard | No | Full | Use `AppContentWidth.standard`, add event-type filter chips and tap-to-transaction links. |
| Worker Production History | `lib/features/production_history/presentation/pages/worker_production_history_page.dart` | 243 | Standard | No | Full | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable`. |
| Process History | `lib/features/production_history/presentation/pages/process_history_page.dart` | 309 | Standard | No | Full | Upgrade to `AppContentWidth.wide` + paginated/sortable `AppDataTable`. |
| Inspection Queue (QC) | `lib/features/production_history/presentation/pages/inspection_queue_page.dart` | 776 | Standard | No | Full | Upgrade to `AppContentWidth.wide`, clear reconciliation strip, PIN auth prompt parity on Web/Native. |
| Production Transaction Detail | `lib/features/production_history/presentation/pages/production_transaction_detail_page.dart` | 303 | Standard | No | Err + Skel | Use `AppContentWidth.standard`, clear cross-links to Lot, Worker, Process, and Ledger. |

### 2.8 Reports, Inventory & Daily Summary
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Reports Hub | `lib/features/reports/presentation/pages/reports_page.dart` | 1575 | Standard | Yes | Full | Upgrade to `AppContentWidth.wide`, add search/sorting/pagination on report tables, enable Web Blob Excel/CSV & Browser Print/PDF. |
| Daily Summary | `lib/features/reports/presentation/pages/daily_summary_page.dart` | 481 | Standard | No | Full | Use `AppContentWidth.wide`, responsive 2-col layout on desktop. |
| Inventory Overview | `lib/features/inventory/presentation/pages/inventory_overview_page.dart` | 366 | Collapsible | Yes | Empty + Err | Upgrade to `AppContentWidth.wide` with paginated/sortable `AppDataTable`. |

### 2.9 Settings, Security, Backup & Help (12 Pages)
| Screen | File | Lines | Scroll Mode | Table | Empty/Error/Skeleton | Findings & Planned Improvements |
|---|---|---:|---|---|---|---|
| Settings Home | `lib/features/settings/presentation/pages/settings_home_page.dart` | 316 | Standard | No | Static | Use `AppContentWidth.narrow`, add quick entry to **Designs & Colours**, responsive 2-col grid on desktop. |
| Business Profile | `lib/features/business_profile/presentation/pages/business_profile_page.dart` | 329 | Standard | No | Err only | Use `AppContentWidth.narrow`, `AppFormSection`. |
| Stock & Labour Settings | `lib/features/settings/presentation/pages/stock_labour_settings_page.dart` | 444 | Standard | No | Err + Skel | Keep finalized Accepted-Only payment banner prominent and legacy toggles read-only; narrow width tier. |
| Appearance Settings | `lib/features/settings/presentation/pages/appearance_settings_page.dart` | 152 | Standard | No | Static | Verify Light / Dark / System theme & EN/GU switching, narrow width tier. |
| Notification Settings | `lib/features/notifications/presentation/pages/notification_settings_page.dart` | 418 | Standard | No | Skel only | Guard Web gracefully (informative notice when browser notifications are unavailable offline). |
| Security Settings | `lib/features/security/presentation/pages/security_settings_page.dart` | 418 | Standard | No | Static | Guard Web biometric availability gracefully; preserve PIN + Approval Auth toggle. |
| PIN Setup | `lib/features/security/presentation/pages/pin_setup_page.dart` | 341 | Standard | No | Static | Use `AppContentWidth.narrow`; ensure Web-safe `PinHasher`. |
| PIN Recovery | `lib/features/security/presentation/pages/pin_recovery_page.dart` | 367 | Standard | No | Static | Use `AppContentWidth.narrow`; ensure Web-safe `PinHasher`. |
| Backup & Restore | `lib/features/backup/presentation/pages/backup_restore_page.dart` | 407 | Standard | No | Inline | Use `AppContentWidth.narrow`; support both Native WAL `.zip` backup/restore and Web JSON/snapshot export/restore cleanly. |
| Help & Guidance (+ Detail) | `lib/features/settings/presentation/pages/help_guidance_page.dart` | 269 | Standard | No | Empty | Use `AppContentWidth.standard`; ensure plain-language guides match finalized QC & Earnings rules. |
| About StitchFlow | `lib/features/settings/presentation/pages/about_stitchflow_page.dart` | 199 | Standard | No | Static | Use `AppContentWidth.narrow`. |
| Design System Showcase | `lib/core/design_system/design_system_showcase_page.dart` | — | Standard | Yes | Static | Update to showcase new width tiers, paginated `AppDataTable`, `AppBreadcrumbBar`, `AppFormSection`, `AppFilterBar`. |

---

## 3. Core Reusable Widgets Inventory (`lib/core/widgets/`)

All 32 existing shared widgets were audited:
- **Layout & Navigation:** `app_scaffold.dart`, `app_collapsible_header.dart`, `responsive_navigation.dart`, `app_glass_backdrop.dart`, `app_glass_surface.dart`
- **Cards, Data & Metrics:** `app_card.dart`, `app_data_table.dart`, `app_metric_tile.dart`, `app_animated_number.dart`, `app_colour_swatch.dart`, `app_status_badge.dart`
- **Forms & Inputs:** `app_button.dart`, `app_icon_button.dart`, `app_text_field.dart`, `app_dropdown.dart`, `app_checkbox.dart`, `app_radio.dart`, `app_switch.dart`, `app_date_picker.dart`, `app_search_field.dart`
- **Typography & Headers:** `app_heading.dart`, `app_text.dart`, `app_section_header.dart`
- **Modals & Feedback:** `app_dialog.dart`, `app_confirmation_dialog.dart`, `app_bottom_sheet.dart`, `app_feedback.dart`, `app_empty_state.dart`, `app_error_view.dart`, `app_loader.dart`, `app_skeleton.dart`, `app_success_state.dart`
- **Feature Dialogs/Sheets:** `visual_colour_picker_sheet.dart`, `security_reauth_dialog.dart`, `app_lock_gate.dart`
