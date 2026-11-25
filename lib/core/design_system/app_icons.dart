import 'package:business_manager/core/design_system/stitch_icons.g.dart';
import 'package:material_ui/material_ui.dart';

/// StitchFlow's single icon vocabulary: **one icon per meaning**, used on every
/// screen, button, menu, tile and report.
///
/// - Textile-specific actions use the custom `StitchIcons` font (drawn for
///   StitchFlow in `assets/icons/svg/`, built by `tool/icons`).
/// - Everything else uses Material Symbols in the **rounded** family only.
///
/// Rules:
/// - Screens never use `Icons.` directly; add a semantic name here instead
///   (enforced by `test/unit/app_icons_usage_test.dart`).
/// - Pick the icon by what the action *means*, not by what looks nice on one
///   screen — "Receive return" must look the same in the dashboard, menus,
///   stock page, timeline and reports.
abstract final class AppIcons {
  // ── Navigation (outlined + selected pairs) ──────────────────────────────
  static const IconData dashboard = Icons.space_dashboard_outlined;
  static const IconData dashboardSelected = Icons.space_dashboard_rounded;
  static const IconData lots = StitchIcons.lot;
  static const IconData lotsSelected = StitchIcons.lot;
  static const IconData stock = Icons.swap_horiz_rounded;
  static const IconData stockSelected = Icons.swap_horiz_rounded;
  static const IconData workers = StitchIcons.karigar;
  static const IconData workersSelected = StitchIcons.karigar;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings_rounded;
  static const IconData home = Icons.home_rounded;
  static const IconData moreScreens = Icons.apps_rounded;

  // ── Lots, designs & colours ─────────────────────────────────────────────
  static const IconData lot = StitchIcons.lot;
  static const IconData lotAdd = StitchIcons.lotAdd;
  static const IconData designs = StitchIcons.design;
  static const IconData colour = StitchIcons.colour;
  static const IconData archive = Icons.archive_rounded;

  // ── Stock ───────────────────────────────────────────────────────────────
  static const IconData stockIssue = StitchIcons.stockIssue;
  static const IconData receiveReturn = StitchIcons.receiveReturn;
  static const IconData stockMovements = Icons.swap_horiz_rounded;
  static const IconData inventory = Icons.inventory_rounded;
  static const IconData factory = Icons.warehouse_rounded;
  static const IconData dispatch = Icons.local_shipping_rounded;
  static const IconData damaged = StitchIcons.damaged;
  static const IconData repair = Icons.build_rounded;
  static const IconData locked = Icons.lock_rounded;

  // ── Production ──────────────────────────────────────────────────────────
  static const IconData process = StitchIcons.process;
  static const IconData cutting = StitchIcons.cutting;
  static const IconData stitching = StitchIcons.process;
  static const IconData routeTransfer = StitchIcons.routeTransfer;
  static const IconData assignWorker = Icons.assignment_ind_rounded;
  static const IconData qcInspect = StitchIcons.qcInspect;
  static const IconData qcPassed = Icons.verified_rounded;
  static const IconData productionHistory = Icons.history_rounded;
  static const IconData processHistory = Icons.manage_history_rounded;
  static const IconData timeline = Icons.timeline_rounded;
  static const IconData addCharge = Icons.add_card_rounded;
  static const IconData resume = Icons.play_circle_outline_rounded;
  static const IconData pause = Icons.pause_circle_outline_rounded;
  static const IconData currentStep = Icons.radio_button_checked_rounded;
  static const IconData milestone = Icons.flag_rounded;

  // ── Workers ─────────────────────────────────────────────────────────────
  static const IconData worker = StitchIcons.karigar;
  static const IconData workerAdd = Icons.person_add_alt_1_rounded;
  static const IconData workerInactive = Icons.person_off_rounded;
  static const IconData work = Icons.work_outline_rounded;
  static const IconData workHistory = Icons.work_history_rounded;
  static const IconData link = Icons.link_rounded;
  static const IconData linkAdd = Icons.add_link_rounded;
  static const IconData unlink = Icons.link_off_rounded;

  // ── Money ───────────────────────────────────────────────────────────────
  static const IconData payment = Icons.payments_rounded;
  static const IconData accounting = Icons.account_balance_wallet_rounded;
  static const IconData ledger = StitchIcons.ledger;
  static const IconData adjustment = StitchIcons.adjustment;
  static const IconData pieceRate = StitchIcons.pieceRate;
  static const IconData rateHistory = Icons.price_change_rounded;
  static const IconData rupee = Icons.currency_rupee_rounded;
  static const IconData receipt = Icons.receipt_rounded;
  static const IconData reverse = Icons.undo_rounded;
  static const IconData trend = Icons.trending_up_rounded;

  // ── Reports, export & data ──────────────────────────────────────────────
  static const IconData reports = Icons.analytics_rounded;
  static const IconData dailySummary = Icons.today_rounded;
  static const IconData print = Icons.print_rounded;
  static const IconData excel = Icons.table_view_rounded;
  static const IconData pdf = Icons.picture_as_pdf_rounded;
  static const IconData document = Icons.description_rounded;
  static const IconData share = Icons.ios_share_rounded;
  static const IconData download = Icons.download_rounded;
  static const IconData folder = Icons.folder_open_rounded;
  static const IconData storage = Icons.storage_rounded;
  static const IconData backup = Icons.backup_rounded;
  static const IconData restore = Icons.settings_backup_restore_rounded;

  // ── Security ────────────────────────────────────────────────────────────
  static const IconData lock = Icons.lock_rounded;
  static const IconData unlock = Icons.lock_open_rounded;
  static const IconData pin = Icons.pin_rounded;
  static const IconData recoveryKey = Icons.key_rounded;
  static const IconData biometric = Icons.fingerprint_rounded;
  static const IconData security = Icons.verified_user_rounded;
  static const IconData shield = Icons.shield_rounded;

  // ── Settings & app ──────────────────────────────────────────────────────
  static const IconData appearance = Icons.contrast_rounded;
  static const IconData stockLabourSettings = Icons.settings_suggest_rounded;
  static const IconData business = Icons.storefront_rounded;
  static const IconData notifications = Icons.notifications_rounded;
  static const IconData notificationsActive =
      Icons.notifications_active_rounded;
  static const IconData language = Icons.translate_rounded;
  static const IconData help = Icons.help_outline_rounded;
  static const IconData guide = Icons.menu_book_rounded;
  static const IconData tip = Icons.lightbulb_outline_rounded;
  static const IconData getStarted = Icons.rocket_launch_rounded;
  static const IconData quick = Icons.bolt_rounded;
  static const IconData showcase = Icons.widgets_rounded;
  static const IconData brand = StitchIcons.process;
  static const IconData phone = Icons.phone_rounded;
  static const IconData location = Icons.location_on_rounded;
  static const IconData camera = Icons.photo_camera_rounded;
  static const IconData gallery = Icons.photo_library_rounded;
  static const IconData imageError = Icons.broken_image_rounded;
  static const IconData autoFill = Icons.auto_fix_high_rounded;

  // ── Generic actions ─────────────────────────────────────────────────────
  static const IconData add = Icons.add_rounded;
  static const IconData addCircle = Icons.add_circle_outline_rounded;
  static const IconData remove = Icons.remove_circle_outline_rounded;
  static const IconData edit = Icons.edit_rounded;
  static const IconData notes = Icons.edit_note_rounded;
  static const IconData delete = Icons.delete_outline_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData confirm = Icons.check_rounded;
  static const IconData doneAll = Icons.done_all_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData cancel = Icons.cancel_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData search = Icons.search_rounded;
  static const IconData filter = Icons.tune_rounded;
  static const IconData clearFilter = Icons.filter_alt_off_rounded;
  static const IconData send = Icons.send_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_ios_rounded;
  static const IconData chevronRight = Icons.chevron_right_rounded;
  static const IconData chevronLeft = Icons.chevron_left_rounded;
  static const IconData expandMore = Icons.expand_more_rounded;
  static const IconData expandLess = Icons.expand_less_rounded;
  static const IconData backspace = Icons.backspace_rounded;
  static const IconData date = Icons.calendar_today_rounded;
  static const IconData time = Icons.schedule_rounded;
  static const IconData tag = Icons.tag_rounded;
  static const IconData number = Icons.numbers_rounded;
  static const IconData title = Icons.title_rounded;
  static const IconData label = Icons.label_outline_rounded;
  static const IconData empty = Icons.inbox_rounded;

  // ── Status ──────────────────────────────────────────────────────────────
  static const IconData success = Icons.check_circle_rounded;
  static const IconData successOutline = Icons.check_circle_outline_rounded;
  static const IconData pending = Icons.pending_actions_rounded;
  static const IconData waiting = Icons.hourglass_top_rounded;
  static const IconData warning = Icons.warning_amber_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;

  /// Icon for a production process by its (English or Gujarati) name, so
  /// cutting, stitching and others are recognisable in lists; falls back to
  /// the generic [process] mark.
  static IconData processIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('cut') || n.contains('કટ')) return cutting;
    if (n.contains('stitch') ||
        n.contains('sew') ||
        n.contains('silai') ||
        n.contains('સિલાઈ')) {
      return stitching;
    }
    if (n.contains('check') || n.contains('qc') || n.contains('inspect')) {
      return qcInspect;
    }
    if (n.contains('press') || n.contains('iron')) return Icons.iron_rounded;
    if (n.contains('pack')) return Icons.inventory_2_rounded;
    if (n.contains('embroid') || n.contains('ભરત')) return designs;
    return process;
  }

  /// Every registry entry by name, for the showcase grid.
  static const Map<String, IconData> catalogue = {
    'lot': lot,
    'lotAdd': lotAdd,
    'designs': designs,
    'colour': colour,
    'stockIssue': stockIssue,
    'receiveReturn': receiveReturn,
    'stockMovements': stockMovements,
    'inventory': inventory,
    'factory': factory,
    'damaged': damaged,
    'repair': repair,
    'process': process,
    'cutting': cutting,
    'routeTransfer': routeTransfer,
    'assignWorker': assignWorker,
    'qcInspect': qcInspect,
    'qcPassed': qcPassed,
    'productionHistory': productionHistory,
    'processHistory': processHistory,
    'worker': worker,
    'workerAdd': workerAdd,
    'payment': payment,
    'accounting': accounting,
    'ledger': ledger,
    'adjustment': adjustment,
    'pieceRate': pieceRate,
    'rateHistory': rateHistory,
    'reports': reports,
    'dailySummary': dailySummary,
    'backup': backup,
    'restore': restore,
    'lock': lock,
    'pin': pin,
    'biometric': biometric,
    'appearance': appearance,
    'add': add,
    'edit': edit,
    'delete': delete,
    'save': save,
    'search': search,
    'filter': filter,
    'share': share,
    'print': print,
    'refresh': refresh,
    'success': success,
    'pending': pending,
    'warning': warning,
    'error': error,
  };
}
