import 'package:business_manager/l10n/generated/app_localizations.dart';

/// Maps canonical Process Routing error codes emitted by [JobRoutingCubit]
/// into localized English/Gujarati messages.
abstract final class RoutingErrorLocalizer {
  static String localize(AppLocalizations l10n, String code) {
    return switch (code) {
      'job_not_found' => l10n.routingErrJobNotFound,
      'not_ready' => l10n.routingErrNotReady,
      'insufficient_good_stock' => l10n.routingErrExceedsFactoryStock,
      'exceeds_dispatched_quantity' => l10n.routingErrExceedsDispatched,
      'exceeds_held_quantity' => l10n.routingErrExceedsWorkerStock,
      'exceeds_pending_quantity' => l10n.routingErrExceedsReturnable,
      'unaccounted_quantity_remaining' => l10n.routingErrPendingRemaining,
      'cannot_cancel_with_pending_stock' => l10n.routingErrHeldPiecesCancel,
      'same_worker_and_process' => l10n.routingErrSameWorkerProcess,
      'rate_override_reason_required' => l10n.routingErrRateOverrideReason,
      'exceeds_outstanding_payable' => l10n.routingErrPaymentExceedsPayable,
      'invalid_rate' => l10n.routingInvalidRateError,
      'invalid_amount' => l10n.routingInvalidAmountError,
      'description_required' => l10n.routingErrDescriptionRequired,
      'reason_required' => l10n.routingErrReasonRequired,
      'invalid_quantity' => l10n.routingInvalidQuantityError,
      'process_required' => l10n.routingErrProcessRequired,
      'worker_required' => l10n.routingErrWorkerRequired,
      'sku_required' => l10n.routingErrSkuRequired,
      'process_already_closed' => l10n.routingErrAlreadyClosed,
      _ => code,
    };
  }
}
