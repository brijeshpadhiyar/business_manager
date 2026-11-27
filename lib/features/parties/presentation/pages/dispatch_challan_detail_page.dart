import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/dispatch/:id` — View a Dispatch Challan, Share Slip, Return, or Reverse.
final class DispatchChallanDetailPage extends StatefulWidget {
  const DispatchChallanDetailPage({super.key, required this.challanId});

  final String challanId;

  @override
  State<DispatchChallanDetailPage> createState() =>
      _DispatchChallanDetailPageState();
}

final class _DispatchChallanDetailPageState
    extends State<DispatchChallanDetailPage> {
  final _repo = getIt<PartyRepository>();
  DispatchChallanView? _view;
  PartyLedgerDetail? _partyDetail;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final view = await _repo.getDispatchChallanDetail(widget.challanId);
      final party = view != null
          ? await _repo.getPartyLedgerDetail(view.challan.partyId)
          : null;
      if (!mounted) return;
      setState(() {
        _view = view;
        _partyDetail = party;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e;
      });
    }
  }

  Future<void> _reverse() async {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    final ok = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: l10n.dispatchReverseConfirmTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              l10n.dispatchReverseConfirmMessage,
              variant: AppTextVariant.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: ctrl,
              label: l10n.stockReverseReasonLabel,
              maxLines: 2,
            ),
          ],
        ),
        confirmLabel: l10n.dispatchReverseAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogCtx).pop(true),
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.isEmpty || !mounted) return;

    try {
      await _repo.reverseDispatchChallan(
        challanId: widget.challanId,
        reason: reason,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, l10n.dispatchReversedBadge);
      await _load();
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final canDispatch = PermissionGate.hasPermission(
      context,
      AppPermission.createDispatchAndReturns,
    );

    return AppScaffold(
      title: _view?.challan.challanNumber ?? l10n.dispatchDetailHeading,
      contentWidth: AppContentWidth.standard,
      onRefresh: _load,
      actions: [
        if (_view != null)
          AppIconButton(
            icon: AppIcons.share,
            tooltip: l10n.dispatchShareSlipAction,
            onPressed: () async {
              final slip = await SlipBuilderHelper.buildPartyDispatchChallan(
                view: _view!,
                discountLabel: l10n.dispatchDiscountLabel,
                otherChargesLabel: l10n.dispatchOtherChargesLabel,
                outstandingReceivablePaise:
                    _partyDetail?.summary.outstandingReceivablePaise ?? 0,
                advanceCreditPaise:
                    _partyDetail?.summary.advanceCreditPaise ?? 0,
              );
              if (!context.mounted) return;
              await SlipShareSheet.show(context, slip);
            },
          ),
      ],
      body: _isLoading
          ? const AppSkeletonList(itemCount: 4)
          : _error != null || _view == null
          ? AppErrorView(
              title: l10n.errorUnexpected,
              message: _error != null
                  ? ValidationLocalizer.describeError(l10n, _error!)
                  : l10n.errorUnexpected,
              onRetry: _load,
            )
          : ListView(
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              _view!.partyName,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                            AppText(
                              IstDateTimeHelper.formatIstDateTime(
                                _view!.challan.transactionAt,
                                locale: localeCode,
                              ),
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: _view!.isReversed
                                ? l10n.dispatchReversedBadge
                                : MoneyFormatter.formatPaise(
                                    _view!.challan.netAmountPaise,
                                  ),
                            tone: _view!.isReversed
                                ? AppStatusTone.neutral
                                : AppStatusTone.good,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: l10n.dispatchShareSlipAction,
                            icon: AppIcons.share,
                            onPressed: () async {
                              final slip =
                                  await SlipBuilderHelper.buildPartyDispatchChallan(
                                    view: _view!,
                                    discountLabel: l10n.dispatchDiscountLabel,
                                    otherChargesLabel:
                                        l10n.dispatchOtherChargesLabel,
                                    outstandingReceivablePaise:
                                        _partyDetail
                                            ?.summary
                                            .outstandingReceivablePaise ??
                                        0,
                                    advanceCreditPaise:
                                        _partyDetail
                                            ?.summary
                                            .advanceCreditPaise ??
                                        0,
                                  );
                              if (!context.mounted) return;
                              await SlipShareSheet.show(context, slip);
                            },
                          ),
                          if (canDispatch && !_view!.isReversed) ...[
                            AppButton(
                              label: l10n.buyerReturnNewAction,
                              icon: AppIcons.buyerReturn,
                              variant: AppButtonVariant.secondary,
                              onPressed: () async {
                                await context.push(
                                  RoutePaths.partyReturn(
                                    _view!.challan.partyId,
                                    challanId: _view!.challan.id,
                                  ),
                                );
                                if (context.mounted) _load();
                              },
                            ),
                            AppButton(
                              label: l10n.dispatchReverseAction,
                              icon: AppIcons.reverse,
                              variant: AppButtonVariant.outlined,
                              onPressed: _reverse,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in _view!.items) ...[
                  AppCard.listItem(
                    child: AppActionRow(
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            '${item.lotNumber} • ${item.designName} • ${item.colourName}',
                            fontWeight: FontWeight.w600,
                          ),
                          AppText(
                            '${item.quantity} ${l10n.piecesUnit} × ${MoneyFormatter.formatPaise(item.ratePaise)}',
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                      ),
                      actions: [
                        AppText(
                          MoneyFormatter.formatPaise(item.lineTotalPaise),
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}
