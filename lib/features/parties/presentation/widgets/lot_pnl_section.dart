import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Embeddable Lot Profit & Loss + Direct Costs card for [LotDetailPage].
final class LotPnlSection extends StatefulWidget {
  const LotPnlSection({super.key, required this.lotId});

  final String lotId;

  @override
  State<LotPnlSection> createState() => _LotPnlSectionState();
}

final class _LotPnlSectionState extends State<LotPnlSection> {
  LotProfitLossSummary? _summary;
  List<LotDirectCostEntity> _costs = const [];
  bool _loading = true;

  PartyRepository? get _repo =>
      getIt.isRegistered<PartyRepository>() ? getIt<PartyRepository>() : null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = _repo;
    if (repo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final pnl = await repo.getLotProfitLoss(widget.lotId);
      final costs = await repo.getLotDirectCosts(widget.lotId);
      if (!mounted) return;
      setState(() {
        _summary = pnl;
        _costs = costs;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _categoryLabel(BuildContext context, LotCostCategory c) {
    final l10n = context.l10n;
    return switch (c) {
      LotCostCategory.fabric => l10n.lotDirectCostCatFabric,
      LotCostCategory.trims => l10n.lotDirectCostCatTrims,
      LotCostCategory.transport => l10n.lotDirectCostCatTransport,
      LotCostCategory.packing => l10n.lotDirectCostCatPacking,
      LotCostCategory.other => l10n.lotDirectCostCatOther,
    };
  }

  Future<void> _showAddCostSheet() async {
    final repo = _repo;
    if (repo == null) return;
    final l10n = context.l10n;
    final formKey = GlobalKey<FormState>();
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var category = LotCostCategory.fabric;
    var txAt = IstDateTimeHelper.nowUtcMillis();

    final saved = await AppBottomSheet.show<bool>(
      context,
      title: l10n.lotDirectCostHeading,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                l10n.lotDirectCostCategoryLabel,
                variant: AppTextVariant.label,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppChipGroup<LotCostCategory>(
                items: LotCostCategory.values,
                value: category,
                onChanged: (c) => setSheetState(() => category = c),
                itemLabelBuilder: (c) => _categoryLabel(ctx, c),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: descCtrl,
                label: l10n.lotDirectCostDescriptionLabel,
                validator: ValidationLocalizer.wrap(
                  l10n,
                  (v) => AppValidators.nameValidator(v),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppFormRow(
                children: [
                  AppTextField(
                    controller: amtCtrl,
                    label: l10n.lotDirectCostAmountLabel,
                    prefixIcon: AppIcons.rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.amountValidator(v),
                    ),
                  ),
                  AppDatePicker(
                    label: l10n.stockTransactionDateTimeLabel,
                    selectedUtcMillis: txAt,
                    onDateSelectedUtcMillis: (ms) =>
                        setSheetState(() => txAt = ms),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: notesCtrl,
                label: l10n.lotNotesLabel,
              ),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.actionSave,
                icon: AppIcons.save,
                isExpanded: true,
                onPressed: () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final paise = AppValidators.parseRupeesToPaiseExact(
                    amtCtrl.text,
                    allowZero: false,
                  ).paise;
                  if (paise == null || paise <= 0) return;
                  try {
                    await repo.addLotDirectCost(
                      lotId: widget.lotId,
                      category: category,
                      description: descCtrl.text,
                      amountPaise: paise,
                      notes: notesCtrl.text,
                      transactionAtUtcMillis: txAt,
                    );
                    if (sheetCtx.mounted) Navigator.of(sheetCtx).pop(true);
                  } catch (e) {
                    if (!sheetCtx.mounted) return;
                    AppFeedback.showError(
                      sheetCtx,
                      ValidationLocalizer.describeError(l10n, e),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
    descCtrl.dispose();
    amtCtrl.dispose();
    notesCtrl.dispose();
    if (saved == true && mounted) {
      AppFeedback.showSuccess(context, l10n.lotDirectCostSavedSuccess);
      await _load();
    }
  }

  Future<void> _reverseCost(LotDirectCostEntity cost) async {
    final repo = _repo;
    if (repo == null) return;
    final l10n = context.l10n;
    final ctrl = TextEditingController();
    final ok = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: l10n.lotDirectCostReverseAction,
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
    if (ok != true || reason.isEmpty || !mounted) return;
    try {
      await repo.reverseLotDirectCost(costId: cost.id, reason: reason);
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
    if (_repo == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    if (_loading) return const SizedBox.shrink();
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    final canManageCosts = PermissionGate.hasPermission(
      context,
      AppPermission.manageLotDirectCosts,
    );
    final canDispatch = PermissionGate.hasPermission(
      context,
      AppPermission.createDispatchAndReturns,
    );
    final reversedIds = _costs
        .where((c) => c.reversesCostId != null)
        .map((c) => c.reversesCostId!)
        .toSet();
    final activeCosts = _costs
        .where((c) => !c.isReversal && !reversedIds.contains(c.id))
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppActionRow(
            content: AppHeading(
              l10n.lotPnlHeading,
              level: AppHeadingLevel.h3,
            ),
            actions: [
              if (s.profitMarginPercent != null)
                AppStatusBadge(
                  label:
                      '${l10n.lotPnlMarginLabel}: ${s.profitMarginPercent!.toStringAsFixed(1)}%',
                  tone: s.netProfitPaise >= 0
                      ? AppStatusTone.good
                      : AppStatusTone.damaged,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppSummaryStrip(
            metrics: [
              AppSummaryMetric(
                label: l10n.lotPnlNetRevenueLabel,
                value: MoneyFormatter.formatPaise(s.netRevenuePaise),
                tone: AppStatusTone.info,
                icon: AppIcons.dispatch,
              ),
              AppSummaryMetric(
                label: l10n.lotPnlWorkerLabourLabel,
                value: MoneyFormatter.formatPaise(s.workerLabourPaise),
                tone: AppStatusTone.neutral,
                icon: AppIcons.payment,
              ),
              AppSummaryMetric(
                label: l10n.lotPnlDirectCostsLabel,
                value: MoneyFormatter.formatPaise(s.directCostsPaise),
                tone: AppStatusTone.neutral,
                icon: AppIcons.directCost,
              ),
              AppSummaryMetric(
                label: l10n.lotPnlNetProfitLabel,
                value: MoneyFormatter.formatPaise(s.netProfitPaise),
                tone: s.netProfitPaise >= 0
                    ? AppStatusTone.good
                    : AppStatusTone.damaged,
                icon: AppIcons.profitLoss,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
                      RoutePaths.dispatchCreate(lotId: widget.lotId),
                    );
                    if (mounted) _load();
                  },
                ),
              if (canManageCosts)
                AppButton(
                  label: l10n.lotDirectCostAddAction,
                  icon: AppIcons.directCost,
                  variant: AppButtonVariant.outlined,
                  onPressed: _showAddCostSheet,
                ),
            ],
          ),
          if (activeCosts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const AppDivider(),
            const SizedBox(height: AppSpacing.xs),
            for (final cost in activeCosts)
              AppActionRow(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      cost.description,
                      variant: AppTextVariant.bodyMedium,
                    ),
                    AppText(
                      _categoryLabel(context, cost.category),
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  AppText(
                    MoneyFormatter.formatPaise(cost.amountPaise),
                    variant: AppTextVariant.label,
                  ),
                  if (canManageCosts)
                    AppIconButton(
                      icon: AppIcons.reverse,
                      tooltip: l10n.lotDirectCostReverseAction,
                      onPressed: () => _reverseCost(cost),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
