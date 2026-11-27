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
import 'package:business_manager/features/parties/presentation/bloc/party_detail_cubit.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/parties/:id` — Party Khata, Dispatch Challans, Returns & Receipts hub.
final class PartyDetailPage extends StatelessWidget {
  const PartyDetailPage({super.key, required this.partyId});

  final String partyId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PartyDetailCubit>(
      create: (_) => getIt<PartyDetailCubit>()..loadParty(partyId),
      child: _PartyDetailView(partyId: partyId),
    );
  }
}

enum _PartyDetailSection { ledger, challans, returns, payments }

final class _PartyDetailView extends StatefulWidget {
  const _PartyDetailView({required this.partyId});

  final String partyId;

  @override
  State<_PartyDetailView> createState() => _PartyDetailViewState();
}

final class _PartyDetailViewState extends State<_PartyDetailView> {
  _PartyDetailSection _section = _PartyDetailSection.ledger;

  Future<String?> _askReversalReason(BuildContext context) async {
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    final ok = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: l10n.stockReverseReasonLabel,
        content: AppTextField(
          controller: ctrl,
          label: l10n.stockReverseReasonLabel,
          maxLines: 2,
        ),
        confirmLabel: l10n.actionConfirm,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
        onConfirm: () => Navigator.of(dialogCtx).pop(true),
      ),
    );
    final reason = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || reason.isEmpty) return null;
    return reason;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final canDispatch = PermissionGate.hasPermission(
      context,
      AppPermission.createDispatchAndReturns,
    );
    final canCollect = PermissionGate.hasPermission(
      context,
      AppPermission.recordPartyReceipts,
    );

    return BlocBuilder<PartyDetailCubit, PartyDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        final cubit = context.read<PartyDetailCubit>();

        return AppScaffold(
          title: detail?.party.name ?? l10n.partyKhataHeading,
          contentWidth: AppContentWidth.standard,
          onRefresh: () => cubit.loadParty(widget.partyId),
          actions: [
            if (detail != null)
              AppIconButton(
                icon: AppIcons.share,
                tooltip: l10n.partyShareKhataSlip,
                onPressed: () async {
                  final slip =
                      await SlipBuilderHelper.buildPartyKhataStatement(
                        detail: detail,
                      );
                  if (!context.mounted) return;
                  await SlipShareSheet.show(context, slip);
                },
              ),
            if (detail != null && canDispatch)
              AppIconButton(
                icon: AppIcons.edit,
                tooltip: l10n.partyEditAction,
                onPressed: () async {
                  await context.push(RoutePaths.partyEdit(widget.partyId));
                  if (context.mounted) cubit.loadParty(widget.partyId);
                },
              ),
          ],
          body: state.status == PartyDetailStatus.loading && detail == null
              ? const AppSkeletonList(itemCount: 5)
              : state.status == PartyDetailStatus.error || detail == null
              ? AppErrorView(
                  title: l10n.errorUnexpected,
                  message:
                      ValidationLocalizer.describeMessage(
                        l10n,
                        state.errorMessage,
                      ) ??
                      l10n.errorUnexpected,
                  onRetry: () => cubit.loadParty(widget.partyId),
                )
              : ListView(
                  children: [
                    AppSummaryStrip(
                      metrics: [
                        AppSummaryMetric(
                          label: l10n.partyDispatchedNetLabel,
                          value: MoneyFormatter.formatPaise(
                            detail.summary.totalDispatchedNetPaise,
                          ),
                          tone: AppStatusTone.info,
                          icon: AppIcons.dispatch,
                        ),
                        AppSummaryMetric(
                          label: l10n.partyReturnsTotalLabel,
                          value: MoneyFormatter.formatPaise(
                            detail.summary.totalBuyerReturnsPaise,
                          ),
                          tone: AppStatusTone.neutral,
                          icon: AppIcons.buyerReturn,
                        ),
                        AppSummaryMetric(
                          label: l10n.partyCollectedNetLabel,
                          value: MoneyFormatter.formatPaise(
                            detail.summary.totalCollectedNetPaise,
                          ),
                          tone: AppStatusTone.good,
                          icon: AppIcons.payment,
                        ),
                        AppSummaryMetric(
                          label: detail.summary.advanceCreditPaise > 0
                              ? l10n.partyAdvanceCreditLabel
                              : l10n.partyTotalReceivableLabel,
                          value: MoneyFormatter.formatPaise(
                            detail.summary.advanceCreditPaise > 0
                                ? detail.summary.advanceCreditPaise
                                : detail.summary.outstandingReceivablePaise,
                          ),
                          tone: detail.summary.outstandingReceivablePaise > 0
                              ? AppStatusTone.pending
                              : AppStatusTone.good,
                          icon: AppIcons.rupee,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        if (canDispatch)
                          AppButton(
                            label: l10n.dispatchNewAction,
                            icon: AppIcons.dispatch,
                            onPressed: () async {
                              await context.push(
                                RoutePaths.dispatchCreate(
                                  partyId: widget.partyId,
                                ),
                              );
                              if (context.mounted) {
                                cubit.loadParty(widget.partyId);
                              }
                            },
                          ),
                        if (canCollect)
                          AppButton(
                            label: l10n.partyPaymentNewAction,
                            icon: AppIcons.payment,
                            variant: AppButtonVariant.secondary,
                            onPressed: () async {
                              await context.push(
                                RoutePaths.partyPayment(widget.partyId),
                              );
                              if (context.mounted) {
                                cubit.loadParty(widget.partyId);
                              }
                            },
                          ),
                        if (canDispatch && detail.challans.isNotEmpty)
                          AppButton(
                            label: l10n.buyerReturnNewAction,
                            icon: AppIcons.buyerReturn,
                            variant: AppButtonVariant.outlined,
                            onPressed: () async {
                              await context.push(
                                RoutePaths.partyReturn(widget.partyId),
                              );
                              if (context.mounted) {
                                cubit.loadParty(widget.partyId);
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppChipGroup<_PartyDetailSection>(
                      scrollable: true,
                      items: _PartyDetailSection.values,
                      value: _section,
                      onChanged: (s) => setState(() => _section = s),
                      itemLabelBuilder: (s) => switch (s) {
                        _PartyDetailSection.ledger => l10n.partyTabLedger,
                        _PartyDetailSection.challans =>
                          '${l10n.partyTabChallans} (${detail.challans.where((c) => !c.challan.isReversal).length})',
                        _PartyDetailSection.returns =>
                          '${l10n.partyTabReturns} (${detail.buyerReturns.where((r) => !r.buyerReturn.isReversal).length})',
                        _PartyDetailSection.payments =>
                          '${l10n.partyTabPayments} (${detail.payments.where((p) => p.paymentType != PartyPaymentType.reversal).length})',
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ..._buildSectionContent(
                      context,
                      detail: detail,
                      localeCode: localeCode,
                      canDispatch: canDispatch,
                      canCollect: canCollect,
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<Widget> _buildSectionContent(
    BuildContext context, {
    required PartyLedgerDetail detail,
    required String localeCode,
    required bool canDispatch,
    required bool canCollect,
  }) {
    final l10n = context.l10n;
    final cubit = context.read<PartyDetailCubit>();

    switch (_section) {
      case _PartyDetailSection.ledger:
        if (detail.entries.isEmpty) {
          return [
            AppEmptyState(
              icon: AppIcons.ledger,
              title: l10n.partiesEmptyTitle,
              subtitle: l10n.partiesEmptySubtitle,
            ),
          ];
        }
        return [
          for (final e in detail.entries) ...[
            AppCard.listItem(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionRow(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          e.description,
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          IstDateTimeHelper.formatIstDateTime(
                            e.transactionAt,
                            locale: localeCode,
                          ),
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                    actions: [
                      if (e.isReversed)
                        AppStatusBadge(
                          label: l10n.dispatchReversedBadge,
                          tone: AppStatusTone.neutral,
                        )
                      else
                        AppStatusBadge(
                          label: e.debitPaise > 0
                              ? '+${MoneyFormatter.formatPaise(e.debitPaise)}'
                              : '-${MoneyFormatter.formatPaise(e.creditPaise)}',
                          tone: e.debitPaise > 0
                              ? AppStatusTone.pending
                              : AppStatusTone.good,
                        ),
                    ],
                  ),
                  if (e.notes != null && e.notes!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    AppText(e.notes!, variant: AppTextVariant.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    '${l10n.partyTotalReceivableLabel}: ${MoneyFormatter.formatPaise(e.runningBalancePaise)}',
                    variant: AppTextVariant.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];

      case _PartyDetailSection.challans:
        final visible = detail.challans
            .where((c) => !c.challan.isReversal)
            .toList();
        if (visible.isEmpty) {
          return [
            AppEmptyState(
              icon: AppIcons.dispatch,
              title: l10n.dispatchHeading,
              subtitle: l10n.partiesEmptySubtitle,
            ),
          ];
        }
        return [
          for (final c in visible) ...[
            AppCard.listItem(
              onTap: () async {
                await context.push(RoutePaths.dispatchDetail(c.challan.id));
                if (context.mounted) cubit.loadParty(widget.partyId);
              },
              child: AppActionRow(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${c.challan.challanNumber} • ${c.totalPieces} ${l10n.piecesUnit}',
                      fontWeight: FontWeight.w600,
                    ),
                    AppText(
                      IstDateTimeHelper.formatIstDateTime(
                        c.challan.transactionAt,
                        locale: localeCode,
                      ),
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  AppStatusBadge(
                    label: c.isReversed
                        ? l10n.dispatchReversedBadge
                        : MoneyFormatter.formatPaise(c.challan.netAmountPaise),
                    tone: c.isReversed
                        ? AppStatusTone.neutral
                        : AppStatusTone.info,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];

      case _PartyDetailSection.returns:
        final visible = detail.buyerReturns
            .where((r) => !r.buyerReturn.isReversal)
            .toList();
        if (visible.isEmpty) {
          return [
            AppEmptyState(
              icon: AppIcons.buyerReturn,
              title: l10n.buyerReturnNewAction,
              subtitle: l10n.partiesEmptySubtitle,
            ),
          ];
        }
        return [
          for (final r in visible) ...[
            AppCard.listItem(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionRow(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${r.buyerReturn.returnNumber} • ${r.totalPieces} ${l10n.piecesUnit}',
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          r.buyerReturn.reason,
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                    actions: [
                      AppStatusBadge(
                        label: r.isReversed
                            ? l10n.dispatchReversedBadge
                            : MoneyFormatter.formatPaise(
                                r.buyerReturn.creditAmountPaise,
                              ),
                        tone: r.isReversed
                            ? AppStatusTone.neutral
                            : AppStatusTone.good,
                      ),
                    ],
                  ),
                  if (canDispatch && !r.isReversed) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: l10n.buyerReturnReverseAction,
                      icon: AppIcons.reverse,
                      variant: AppButtonVariant.text,
                      onPressed: () async {
                        final reason = await _askReversalReason(context);
                        if (reason == null || !context.mounted) return;
                        try {
                          await cubit.reverseBuyerReturn(
                            partyId: widget.partyId,
                            buyerReturnId: r.buyerReturn.id,
                            reason: reason,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppFeedback.showError(
                            context,
                            ValidationLocalizer.describeError(l10n, e),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];

      case _PartyDetailSection.payments:
        final visible = detail.payments
            .where((p) => p.paymentType != PartyPaymentType.reversal)
            .toList();
        final reversedIds = detail.payments
            .where((p) => p.reversesPaymentId != null)
            .map((p) => p.reversesPaymentId!)
            .toSet();
        if (visible.isEmpty) {
          return [
            AppEmptyState(
              icon: AppIcons.payment,
              title: l10n.partyPaymentNewAction,
              subtitle: l10n.partiesEmptySubtitle,
            ),
          ];
        }
        return [
          for (final p in visible) ...[
            AppCard.listItem(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionRow(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${p.paymentType.dbValue} • ${p.paymentMode.dbValue}',
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          IstDateTimeHelper.formatIstDateTime(
                            p.transactionAt,
                            locale: localeCode,
                          ),
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                    actions: [
                      AppStatusBadge(
                        label: reversedIds.contains(p.id)
                            ? l10n.dispatchReversedBadge
                            : MoneyFormatter.formatPaise(p.amountPaise),
                        tone: reversedIds.contains(p.id)
                            ? AppStatusTone.neutral
                            : AppStatusTone.good,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      AppButton(
                        label: l10n.partyPaymentShareReceiptAction,
                        icon: AppIcons.share,
                        variant: AppButtonVariant.text,
                        onPressed: () async {
                          final slip =
                              await SlipBuilderHelper.buildPartyPaymentReceipt(
                                party: detail.party,
                                payment: p,
                                outstandingReceivablePaise:
                                    detail.summary.outstandingReceivablePaise,
                                advanceCreditPaise:
                                    detail.summary.advanceCreditPaise,
                              );
                          if (!context.mounted) return;
                          await SlipShareSheet.show(context, slip);
                        },
                      ),
                      if (canCollect && !reversedIds.contains(p.id))
                        AppButton(
                          label: l10n.stockReverseAction,
                          icon: AppIcons.reverse,
                          variant: AppButtonVariant.text,
                          onPressed: () async {
                            final reason = await _askReversalReason(context);
                            if (reason == null || !context.mounted) return;
                            try {
                              await cubit.reversePayment(
                                partyId: widget.partyId,
                                paymentId: p.id,
                                reason: reason,
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              AppFeedback.showError(
                                context,
                                ValidationLocalizer.describeError(l10n, e),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ];
    }
  }
}
