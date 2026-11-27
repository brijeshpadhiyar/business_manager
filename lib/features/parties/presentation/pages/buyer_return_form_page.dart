import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/parties/:id/return` — Record a Good or Damaged Buyer Return.
final class BuyerReturnFormPage extends StatefulWidget {
  const BuyerReturnFormPage({
    super.key,
    required this.partyId,
    this.initialChallanId,
  });

  final String partyId;
  final String? initialChallanId;

  @override
  State<BuyerReturnFormPage> createState() => _BuyerReturnFormPageState();
}

final class _BuyerReturnFormPageState extends State<BuyerReturnFormPage> {
  final _repo = getIt<PartyRepository>();
  final _formKey = GlobalKey<FormState>();
  final _dirty = AppFormDirtyTracker();

  final _returnNumberCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<DispatchChallanView> _challans = const [];
  DispatchChallanView? _selectedChallan;
  DispatchItemEntity? _selectedItem;
  BuyerReturnCondition _condition = BuyerReturnCondition.good;
  int _transactionAt = IstDateTimeHelper.nowUtcMillis();

  bool _isLoading = true;
  bool _isSaving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([
      _returnNumberCtrl,
      _qtyCtrl,
      _rateCtrl,
      _reasonCtrl,
      _notesCtrl,
    ]);
    _load();
  }

  Future<void> _load() async {
    try {
      final challans = (await _repo.getDispatchChallans(
        partyId: widget.partyId,
      )).where((c) => !c.challan.isReversal && !c.isReversed).toList();
      final nextNo = await _repo.suggestNextReturnNumber();
      if (!mounted) return;
      _returnNumberCtrl.text = nextNo;
      _challans = challans;
      _selectedChallan = widget.initialChallanId != null
          ? challans
                .where((c) => c.challan.id == widget.initialChallanId)
                .firstOrNull
          : challans.firstOrNull;
      if (_selectedChallan != null && _selectedChallan!.items.isNotEmpty) {
        _selectItem(_selectedChallan!.items.first);
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

  void _selectItem(DispatchItemEntity item) {
    _selectedItem = item;
    _rateCtrl.text = (item.ratePaise / 100.0).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _dirty.dispose();
    _returnNumberCtrl.dispose();
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedItem == null) {
      AppFeedback.showError(context, l10n.buyerReturnItemsRequiredError);
      return;
    }

    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    final ratePaise =
        AppValidators.parseRupeesToPaiseExact(
          _rateCtrl.text,
          isRequired: false,
          allowZero: true,
        ).paise ??
        0;

    setState(() => _isSaving = true);
    try {
      final res = await _repo.createBuyerReturn(
        partyId: widget.partyId,
        challanId: _selectedChallan?.challan.id,
        returnNumber: _returnNumberCtrl.text,
        items: [
          BuyerReturnLineDraft(
            dispatchItemId: _selectedItem!.id,
            lotId: _selectedItem!.lotId,
            lotDesignId: _selectedItem!.lotDesignId,
            designColourId: _selectedItem!.designColourId,
            returnCondition: _condition,
            quantity: qty,
            ratePaise: ratePaise,
          ),
        ],
        reason: _reasonCtrl.text,
        notes: _notesCtrl.text,
        transactionAtUtcMillis: _transactionAt,
      );
      if (!mounted) return;
      _dirty.reset();
      AppFeedback.showSuccess(
        context,
        l10n.buyerReturnSavedSuccess(res.buyerReturn.returnNumber),
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
    final challanItems = _selectedChallan?.items ?? const <DispatchItemEntity>[];

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.buyerReturnHeading,
        contentWidth: AppContentWidth.narrow,
        bottomAction: (_isLoading || _loadError != null || _challans.isEmpty)
            ? null
            : AppStickyActionBar(
                child: AppButton(
                  label: l10n.actionSave,
                  icon: AppIcons.buyerReturn,
                  isLoading: _isSaving,
                  isExpanded: true,
                  onPressed: _save,
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
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppFormRow(
                            children: [
                              AppTextField(
                                controller: _returnNumberCtrl,
                                label: l10n.buyerReturnNumberLabel,
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
                          const SizedBox(height: AppSpacing.md),
                          AppSelect<DispatchChallanView>(
                            label: l10n.dispatchDetailHeading,
                            items: _challans,
                            value: _selectedChallan,
                            compareFn: (a, b) => a.challan.id == b.challan.id,
                            itemLabelBuilder: (c) =>
                                '${c.challan.challanNumber} (${c.totalPieces} ${l10n.piecesUnit})',
                            onChanged: (c) {
                              _dirty.markDirty();
                              setState(() {
                                _selectedChallan = c;
                                _selectedItem = null;
                                if (c != null && c.items.isNotEmpty) {
                                  _selectItem(c.items.first);
                                }
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppSelect<DispatchItemEntity>(
                            label: l10n.txnDesignColourLabel,
                            items: challanItems,
                            value: _selectedItem,
                            compareFn: (a, b) => a.id == b.id,
                            itemLabelBuilder: (it) =>
                                '${it.lotNumber} • ${it.designName} • ${it.colourName}',
                            itemSubtitleBuilder: (it) =>
                                '${it.quantity} ${l10n.piecesUnit}',
                            onChanged: (it) {
                              _dirty.markDirty();
                              setState(() {
                                if (it != null) _selectItem(it);
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppText(
                            l10n.buyerReturnConditionLabel,
                            variant: AppTextVariant.label,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppChipGroup<BuyerReturnCondition>(
                            items: BuyerReturnCondition.values,
                            value: _condition,
                            onChanged: (c) {
                              _dirty.markDirty();
                              setState(() => _condition = c);
                            },
                            itemLabelBuilder: (c) => switch (c) {
                              BuyerReturnCondition.good =>
                                l10n.buyerReturnConditionGood,
                              BuyerReturnCondition.damaged =>
                                l10n.buyerReturnConditionDamaged,
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppFormRow(
                            children: [
                              AppTextField(
                                controller: _qtyCtrl,
                                label: l10n.lotQtyPcsLabel,
                                prefixIcon: AppIcons.number,
                                keyboardType: TextInputType.number,
                                validator: ValidationLocalizer.wrap(
                                  l10n,
                                  (v) => AppValidators.quantityValidator(v),
                                ),
                              ),
                              AppTextField(
                                controller: _rateCtrl,
                                label: l10n.dispatchRatePerPcLabel,
                                prefixIcon: AppIcons.rupee,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: ValidationLocalizer.wrap(
                                  l10n,
                                  (v) => AppValidators.nonNegativeAmountValidator(v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _reasonCtrl,
                            label: l10n.txnReasonLabel,
                            prefixIcon: AppIcons.notes,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.requiredValidator(v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesCtrl,
                            label: l10n.lotNotesLabel,
                            maxLines: 2,
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
}
