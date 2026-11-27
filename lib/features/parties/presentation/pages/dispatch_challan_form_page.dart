import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class _DispatchLineRow {
  _DispatchLineRow({this.sku});

  DesignColourStockBalance? sku;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController rateCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    rateCtrl.dispose();
  }
}

/// `/dispatch/new` — Guided multi-line Party Dispatch Challan form.
final class DispatchChallanFormPage extends StatefulWidget {
  const DispatchChallanFormPage({
    super.key,
    this.initialPartyId,
    this.initialLotId,
  });

  final String? initialPartyId;
  final String? initialLotId;

  @override
  State<DispatchChallanFormPage> createState() =>
      _DispatchChallanFormPageState();
}

final class _DispatchChallanFormPageState extends State<DispatchChallanFormPage> {
  final _partyRepo = getIt<PartyRepository>();
  final _stockRepo = getIt<StockMovementRepository>();
  final _formKey = GlobalKey<FormState>();
  final _dirty = AppFormDirtyTracker();

  final _challanNumberCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _chargesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<PartyFinancialSummary> _parties = const [];
  List<DesignColourStockBalance> _availableSkus = const [];
  PartyFinancialSummary? _selectedParty;
  int _transactionAt = IstDateTimeHelper.nowUtcMillis();
  final List<_DispatchLineRow> _lines = [];

  bool _isLoading = true;
  bool _isSaving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([
      _challanNumberCtrl,
      _discountCtrl,
      _chargesCtrl,
      _notesCtrl,
    ]);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final parties = await _partyRepo.getAllPartySummaries(
        includeInactive: false,
      );
      final balances = await _stockRepo.getAllDesignColourBalances(
        lotId: widget.initialLotId,
      );
      final inStock = balances
          .where((b) => b.physicalAvailableInHouse > 0)
          .toList();
      final nextNumber = await _partyRepo.suggestNextChallanNumber();

      if (!mounted) return;
      _challanNumberCtrl.text = nextNumber;
      _parties = parties;
      _availableSkus = inStock;
      if (widget.initialPartyId != null) {
        _selectedParty = parties
            .where((p) => p.partyId == widget.initialPartyId)
            .firstOrNull;
      }
      if (_lines.isEmpty && inStock.isNotEmpty) {
        _addLine(sku: inStock.first);
      }
      _dirty.reset();
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e;
      });
    }
  }

  void _addLine({DesignColourStockBalance? sku}) {
    final row = _DispatchLineRow(sku: sku);
    if (sku != null && sku.unitPricePaise > 0) {
      row.rateCtrl.text = (sku.unitPricePaise / 100.0).toStringAsFixed(2);
    }
    row.qtyCtrl.addListener(_onLineChanged);
    row.rateCtrl.addListener(_onLineChanged);
    _lines.add(row);
    setState(() {});
  }

  void _removeLine(int index) {
    final row = _lines.removeAt(index);
    row.dispose();
    _dirty.markDirty();
    setState(() {});
  }

  void _onLineChanged() {
    _dirty.markDirty();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _dirty.dispose();
    _challanNumberCtrl.dispose();
    _discountCtrl.dispose();
    _chargesCtrl.dispose();
    _notesCtrl.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  int get _grossPaise {
    var total = 0;
    for (final l in _lines) {
      final qty = int.tryParse(l.qtyCtrl.text.trim()) ?? 0;
      final rate =
          AppValidators.parseRupeesToPaiseExact(
            l.rateCtrl.text,
            isRequired: false,
            allowZero: true,
          ).paise ??
          0;
      if (qty > 0 && rate >= 0) total += qty * rate;
    }
    return total;
  }

  int get _netPaise {
    final disc = _discountCtrl.text.trim().isEmpty
        ? 0
        : (AppValidators.parseRupeesToPaiseExact(
                _discountCtrl.text,
                isRequired: false,
                allowZero: true,
              ).paise ??
              0);
    final charges = _chargesCtrl.text.trim().isEmpty
        ? 0
        : (AppValidators.parseRupeesToPaiseExact(
                _chargesCtrl.text,
                isRequired: false,
                allowZero: true,
              ).paise ??
              0);
    return _grossPaise - disc + charges;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_selectedParty == null) {
      AppFeedback.showError(context, l10n.dispatchSelectPartyLabel);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final drafts = <DispatchLineDraft>[];
    for (final row in _lines) {
      final sku = row.sku;
      if (sku == null) continue;
      final qty = int.tryParse(row.qtyCtrl.text.trim()) ?? 0;
      final ratePaise = AppValidators.parseRupeesToPaiseExact(
        row.rateCtrl.text,
        allowZero: true,
      ).paise;
      if (qty <= 0 || ratePaise == null) {
        AppFeedback.showError(context, l10n.validationPositiveInt);
        return;
      }
      drafts.add(
        DispatchLineDraft(
          lotId: sku.lotId,
          lotDesignId: sku.lotDesignId,
          designColourId: sku.designColourId,
          quantity: qty,
          ratePaise: ratePaise,
        ),
      );
    }

    if (drafts.isEmpty) {
      AppFeedback.showError(context, l10n.dispatchItemsRequiredError);
      return;
    }

    final discountPaise = _discountCtrl.text.trim().isEmpty
        ? 0
        : (AppValidators.parseRupeesToPaiseExact(
                _discountCtrl.text,
                isRequired: false,
                allowZero: true,
              ).paise ??
              0);
    final otherChargesPaise = _chargesCtrl.text.trim().isEmpty
        ? 0
        : (AppValidators.parseRupeesToPaiseExact(
                _chargesCtrl.text,
                isRequired: false,
                allowZero: true,
              ).paise ??
              0);

    setState(() => _isSaving = true);
    try {
      final view = await _partyRepo.createDispatchChallan(
        partyId: _selectedParty!.partyId,
        challanNumber: _challanNumberCtrl.text,
        items: drafts,
        discountPaise: discountPaise,
        otherChargesPaise: otherChargesPaise,
        notes: _notesCtrl.text,
        transactionAtUtcMillis: _transactionAt,
      );
      if (!mounted) return;
      _dirty.reset();

      final updatedSummary = await _partyRepo.getPartyLedgerDetail(
        _selectedParty!.partyId,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        l10n.dispatchSavedSuccess(view.challan.challanNumber),
        actionLabel: l10n.dispatchShareSlipAction,
        onAction: () async {
          final slip = await SlipBuilderHelper.buildPartyDispatchChallan(
            view: view,
            discountLabel: l10n.dispatchDiscountLabel,
            otherChargesLabel: l10n.dispatchOtherChargesLabel,
            outstandingReceivablePaise:
                updatedSummary?.summary.outstandingReceivablePaise ?? 0,
            advanceCreditPaise: updatedSummary?.summary.advanceCreditPaise ?? 0,
          );
          if (!mounted) return;
          await SlipShareSheet.show(context, slip);
        },
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.dispatchHeading,
        contentWidth: AppContentWidth.standard,
        bottomAction: (_isLoading || _loadError != null || _availableSkus.isEmpty)
            ? null
            : AppStickyActionBar(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppActionRow(
                      content: AppText(
                        l10n.dispatchNetTotalLabel,
                        fontWeight: FontWeight.w600,
                      ),
                      actions: [
                        AppText(
                          MoneyFormatter.formatPaise(_netPaise),
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      label: l10n.dispatchSaveAction,
                      icon: AppIcons.dispatch,
                      isLoading: _isSaving,
                      isExpanded: true,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
        body: _isLoading
            ? const AppSkeletonList(itemCount: 4)
            : _loadError != null
            ? AppErrorView(
                title: l10n.errorUnexpected,
                message: ValidationLocalizer.describeError(l10n, _loadError!),
                onRetry: _load,
              )
            : _parties.isEmpty
            ? AppEmptyState(
                icon: AppIcons.party,
                title: l10n.partiesEmptyTitle,
                subtitle: l10n.partiesEmptySubtitle,
                actionLabel: l10n.partyAddAction,
                onAction: () async {
                  await context.push(RoutePaths.partyCreate);
                  if (context.mounted) _load();
                },
              )
            : _availableSkus.isEmpty
            ? AppEmptyState(
                icon: AppIcons.inventory,
                title: l10n.dispatchNoItemsAvailable,
                subtitle: l10n.stockAvailableGoodLabel,
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppSelect<PartyFinancialSummary>(
                            label: l10n.dispatchSelectPartyLabel,
                            items: _parties,
                            value: _selectedParty,
                            compareFn: (a, b) => a.partyId == b.partyId,
                            itemLabelBuilder: (p) => p.partyName,
                            itemSubtitleBuilder: (p) => p.partyPhone,
                            onChanged: (p) {
                              _dirty.markDirty();
                              setState(() => _selectedParty = p);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppFormRow(
                            children: [
                              AppTextField(
                                controller: _challanNumberCtrl,
                                label: l10n.dispatchChallanNumberLabel,
                                prefixIcon: AppIcons.receipt,
                                validator: ValidationLocalizer.wrap(
                                  l10n,
                                  (v) => AppValidators.nameValidator(v),
                                ),
                              ),
                              AppDatePicker(
                                label: l10n.stockTransactionDateTimeLabel,
                                selectedUtcMillis: _transactionAt,
                                includeTime: true,
                                onDateSelectedUtcMillis: (ms) {
                                  _dirty.markDirty();
                                  setState(() => _transactionAt = ms);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (var i = 0; i < _lines.length; i++) ...[
                      _buildLineCard(context, i),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppButton(
                      label: l10n.dispatchAddItemAction,
                      icon: AppIcons.add,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
                        _dirty.markDirty();
                        _addLine();
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppFormRow(
                            children: [
                              AppTextField(
                                controller: _discountCtrl,
                                label: l10n.dispatchDiscountLabel,
                                prefixIcon: AppIcons.rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                              AppTextField(
                                controller: _chargesCtrl,
                                label: l10n.dispatchOtherChargesLabel,
                                prefixIcon: AppIcons.rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesCtrl,
                            label: l10n.lotNotesLabel,
                            prefixIcon: AppIcons.notes,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppActionRow(
                            content: AppText(
                              l10n.dispatchGrossTotalLabel,
                              variant: AppTextVariant.bodyMedium,
                            ),
                            actions: [
                              AppText(
                                MoneyFormatter.formatPaise(_grossPaise),
                                fontWeight: FontWeight.w600,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLineCard(BuildContext context, int index) {
    final l10n = context.l10n;
    final row = _lines[index];
    final maxAvail = row.sku?.physicalAvailableInHouse ?? 0;
    final qty = int.tryParse(row.qtyCtrl.text.trim()) ?? 0;
    final rate =
        AppValidators.parseRupeesToPaiseExact(
          row.rateCtrl.text,
          isRequired: false,
          allowZero: true,
        ).paise ??
        0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppActionRow(
            content: AppSelect<DesignColourStockBalance>(
              label: l10n.dispatchSelectSkuLabel,
              items: _availableSkus,
              value: row.sku,
              compareFn: (a, b) => a.designColourId == b.designColourId,
              itemLabelBuilder: (b) =>
                  '${b.lotNumber} • ${b.designName} • ${b.colourName}',
              itemSubtitleBuilder: (b) =>
                  l10n.dispatchAvailableQtyBadge(b.physicalAvailableInHouse),
              onChanged: (picked) {
                _dirty.markDirty();
                setState(() {
                  row.sku = picked;
                  if (picked != null &&
                      picked.unitPricePaise > 0 &&
                      row.rateCtrl.text.trim().isEmpty) {
                    row.rateCtrl.text = (picked.unitPricePaise / 100.0)
                        .toStringAsFixed(2);
                  }
                });
              },
            ),
            actions: [
              if (_lines.length > 1)
                AppIconButton(
                  icon: AppIcons.delete,
                  tooltip: l10n.actionDelete,
                  onPressed: () => _removeLine(index),
                ),
            ],
          ),
          if (row.sku != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                AppStatusBadge(
                  label: l10n.dispatchAvailableQtyBadge(maxAvail),
                  tone: AppStatusTone.good,
                ),
                if (qty > 0 && rate >= 0)
                  AppStatusBadge(
                    label: MoneyFormatter.formatPaise(qty * rate),
                    tone: AppStatusTone.info,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppFormRow(
            children: [
              AppTextField(
                controller: row.qtyCtrl,
                label: l10n.lotQtyPcsLabel,
                prefixIcon: AppIcons.number,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final parsed = int.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return l10n.validationPositiveInt;
                  }
                  if (row.sku != null && parsed > maxAvail) {
                    return l10n.dispatchInsufficientStockError;
                  }
                  return null;
                },
              ),
              AppTextField(
                controller: row.rateCtrl,
                label: l10n.dispatchRatePerPcLabel,
                prefixIcon: AppIcons.rupee,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: ValidationLocalizer.wrap(
                  l10n,
                  (v) => AppValidators.nonNegativeAmountValidator(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
