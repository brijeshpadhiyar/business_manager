import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/security/presentation/widgets/security_reauth_dialog.dart';
import 'package:business_manager/features/slips/presentation/slip_builder_helper.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Streamlined Receive Return & Settlement workflow (Steps 2–5) linked to an
/// open ISSUE movement, preserving 100% of domain stock & labour rules.
final class StockSettlementPage extends StatefulWidget {
  const StockSettlementPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<StockSettlementPage> createState() => _StockSettlementPageState();
}

final class _StockSettlementPageState extends State<StockSettlementPage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _formKey = GlobalKey<FormState>();
  final _goodFieldKey = GlobalKey<FormFieldState<String>>();
  final _damagedFieldKey = GlobalKey<FormFieldState<String>>();
  final _lostFieldKey = GlobalKey<FormFieldState<String>>();
  final _shortageFieldKey = GlobalKey<FormFieldState<String>>();
  final _reasonFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _goodCtrl = TextEditingController();
  final _damagedCtrl = TextEditingController();
  final _lostCtrl = TextEditingController();
  final _shortageCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _reasonFocus = FocusNode();

  final _repo = getIt<StockMovementRepository>();
  final _prodHistoryRepo = getIt<ProductionHistoryRepository>();
  final _processRepo = getIt<ProcessRepository>();
  final _idGen = getIt<IdGenerator>();
  static const LabourCalculator _labourCalc = LabourCalculator();

  late String _clientRequestId;

  OpenIssueSummary? _detail;
  List<ProcessEntity> _otherActiveProcesses = const [];
  ProductionReturnMode _returnMode = ProductionReturnMode.immediateInspection;
  bool _loading = true;
  bool _saving = false;
  bool _submittedOnce = false;
  bool _showAdvanced = false;
  String? _loadError;
  String? _submitError;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();

  // Step 5 Success state
  _ReturnSuccessInfo? _successInfo;

  @override
  void initState() {
    super.initState();
    _dirty.watch([
      _goodCtrl,
      _damagedCtrl,
      _lostCtrl,
      _shortageCtrl,
      _reasonCtrl,
      _notesCtrl,
    ]);
    _clientRequestId = _idGen.nextRequestId();
    _load();
  }

  @override
  void dispose() {
    _dirty.dispose();
    _goodCtrl.dispose();
    _damagedCtrl.dispose();
    _lostCtrl.dispose();
    _shortageCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _repo.getIssueDetail(widget.issueId),
        _processRepo.getProcesses(isActiveFilter: true),
      ]);
      final detail = results[0] as OpenIssueSummary?;
      final activeProcs = results[1] as List<ProcessEntity>;
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _loading = false;
          _loadError = 'Issue record not found.';
        });
        return;
      }
      final currentProcId = detail.issueView.movement.processId;
      setState(() {
        _detail = detail;
        _otherActiveProcesses = activeProcs
            .where((p) => p.id != currentProcId)
            .toList();
        _goodCtrl.text = detail.remainingPending > 0
            ? '${detail.remainingPending}'
            : '';
        _damagedCtrl.text = '0';
        _lostCtrl.text = '0';
        _shortageCtrl.text = '0';
        _reasonCtrl.clear();
        _notesCtrl.clear();
        _submitError = null;
        _loading = false;
      });
      _dirty.reset();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  int _qtyOf(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _fillAllGood(int remaining) {
    _dirty.markDirty();
    setState(() {
      _goodCtrl.text = '$remaining';
      _damagedCtrl.text = '0';
      _lostCtrl.text = '0';
      _shortageCtrl.text = '0';
      _submitError = null;
    });
  }

  void _setGoodQtyClamped(int target, int maxGood) {
    _dirty.markDirty();
    final clamped = target.clamp(0, maxGood);
    setState(() {
      _goodCtrl.text = '$clamped';
      _submitError = null;
    });
  }

  int _computeExpectedLabourPaise({
    required StockMovementEntity issue,
    required int good,
    required int damaged,
  }) {
    final mode = issue.lockedBillingMode ?? BillingMode.receivedQty;
    var payable = 0;
    if (good > 0) {
      final planned = _labourCalc.planForSettlement(
        movementType: StockMovementType.returnGood,
        quantity: good,
        lockedRatePaise: issue.appliedRatePaise,
        lockedBillingMode: mode,
        lockedIncludeDamaged: issue.lockedIncludeDamaged,
      );
      if (planned != null && planned.isPayable) {
        payable += planned.amountPaise;
      }
    }
    if (damaged > 0) {
      final planned = _labourCalc.planForSettlement(
        movementType: StockMovementType.returnDamaged,
        quantity: damaged,
        lockedRatePaise: issue.appliedRatePaise,
        lockedBillingMode: mode,
        lockedIncludeDamaged: issue.lockedIncludeDamaged,
      );
      if (planned != null && planned.isPayable) {
        payable += planned.amountPaise;
      }
    }
    return payable;
  }

  Future<void> _submit() async {
    if (_saving || _detail == null) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _goodFieldKey),
        ValidatedFieldAnchor(fieldKey: _damagedFieldKey),
        ValidatedFieldAnchor(fieldKey: _lostFieldKey),
        ValidatedFieldAnchor(fieldKey: _shortageFieldKey),
        ValidatedFieldAnchor(
          fieldKey: _reasonFieldKey,
          focusNode: _reasonFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey),
      ],
    );
    if (!valid) return;
    final l10n = context.l10n;

    final good = _qtyOf(_goodCtrl);
    final damaged = _qtyOf(_damagedCtrl);
    final lost = _qtyOf(_lostCtrl);
    final shortage = _qtyOf(_shortageCtrl);

    if (_returnMode == ProductionReturnMode.pendingInspection) {
      if (good <= 0) {
        setState(() => _submitError = l10n.stockSettlementEmptyError);
        return;
      }
      if (good > _detail!.remainingPending) {
        setState(() => _submitError = l10n.stockSettlementTotalExceedsError);
        return;
      }
      setState(() {
        _saving = true;
        _submitError = null;
      });
      try {
        final res = await _prodHistoryRepo.recordProductionReturn(
          parentIssueId: widget.issueId,
          returnedQuantity: good,
          transactionAtUtcMillis: _transactionAtUtc,
          inspectImmediately: false,
          notes: _notesCtrl.text,
          clientRequestId: _clientRequestId,
        );
        final refreshed = await _repo.getIssueDetail(widget.issueId);
        if (!mounted) return;
        setState(() {
          _saving = false;
          _detail = refreshed ?? _detail;
          _successInfo = _ReturnSuccessInfo(
            designColourId: _detail!.issueView.movement.designColourId,
            lotNumber: _detail!.issueView.lotNumber,
            designName: _detail!.issueView.designName,
            colourName: _detail!.issueView.colourName,
            workerName: _detail!.issueView.workerName ?? '-',
            processName: _detail!.issueView.processName ?? '-',
            goodQty: 0,
            damagedQty: 0,
            lostQty: 0,
            shortageQty: 0,
            updatedPending: res.remainingOutstandingQty,
            labourEarnedPaise: 0,
          );
        });
        AppFeedback.showSuccess(
          context,
          'Logged $good pcs as Pending QC Inspection (₹0 until QC approves).',
        );
      } on DomainValidationException catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _submitError = ValidationLocalizer.localizeDomainException(l10n, e);
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _saving = false;
          _submitError = e.toString();
        });
      }
      return;
    }

    final total = good + damaged + lost + shortage;

    if (total <= 0) {
      setState(() => _submitError = l10n.stockSettlementEmptyError);
      return;
    }
    if (total > _detail!.remainingPending) {
      setState(() => _submitError = l10n.stockSettlementTotalExceedsError);
      return;
    }
    if ((damaged > 0 || lost > 0 || shortage > 0) &&
        _reasonCtrl.text.trim().isEmpty) {
      setState(() => _submitError = l10n.stockSettlementReasonRequiredError);
      return;
    }

    // Rule 6: Require PIN/Biometric authorization before approving accepted qty
    bool authorizedViaPin = false;
    if (good > 0 || damaged > 0) {
      final auth = await SecurityReauthDialog.verifyForApproval(
        context,
        title: l10n.prodHistoryApprovalAuthTitle,
        subtitle: l10n.prodHistoryApprovalAuthSubtitle,
      );
      if (!auth.approved || !mounted) return;
      authorizedViaPin = auth.authorizedViaPin;
    }

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      final result = await _repo.recordSettlement(
        parentIssueId: widget.issueId,
        goodQuantity: good,
        damagedQuantity: damaged,
        lostQuantity: lost,
        shortageQuantity: shortage,
        transactionAtUtcMillis: _transactionAtUtc,
        reason: _reasonCtrl.text,
        notes: _notesCtrl.text,
        authorizedViaPin: authorizedViaPin,
        clientRequestId: _clientRequestId,
      );

      final refreshed = await _repo.getIssueDetail(widget.issueId);
      final issue = _detail!.issueView.movement;
      final labourEarnedPaise = _computeExpectedLabourPaise(
        issue: issue,
        good: good,
        damaged: damaged,
      );

      if (!mounted) return;
      setState(() {
        _saving = false;
        _detail = refreshed ?? _detail;
        _successInfo = _ReturnSuccessInfo(
          designColourId: issue.designColourId,
          lotNumber: _detail!.issueView.lotNumber,
          designName: _detail!.issueView.designName,
          colourName: _detail!.issueView.colourName,
          workerName: _detail!.issueView.workerName ?? '-',
          processName: _detail!.issueView.processName ?? '-',
          goodQty: good,
          damagedQty: damaged,
          lostQty: lost,
          shortageQty: shortage,
          updatedPending: result.remainingPending,
          labourEarnedPaise: labourEarnedPaise,
        );
      });
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = ValidationLocalizer.localizeDomainException(l10n, e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.toString();
      });
    }
  }

  Future<void> _receiveAnother() async {
    final pending = _detail?.remainingPending ?? 0;
    if (pending > 0) {
      setState(() {
        _successInfo = null;
        _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
        _clientRequestId = _idGen.nextRequestId();
      });
      await _load();
    } else {
      context.pushReplacement(RoutePaths.stockReturnPicker);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return AppScaffold(
        title: l10n.stockSettlementHeading,
        body: const AppSkeletonList(itemCount: 3),
      );
    }
    if (_loadError != null || _detail == null) {
      return AppScaffold(
        title: l10n.stockSettlementHeading,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _loadError,
          retryLabel: l10n.actionRetry,
          onRetry: _load,
        ),
      );
    }

    if (_successInfo != null) {
      return _buildSuccessView(context, _successInfo!);
    }

    final detail = _detail!;
    final view = detail.issueView;
    final m = view.movement;
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;

    final good = _qtyOf(_goodCtrl);
    final damaged = _qtyOf(_damagedCtrl);
    final lost = _qtyOf(_lostCtrl);
    final shortage = _qtyOf(_shortageCtrl);
    final totalEntered = good + damaged + lost + shortage;
    final remainingAfter = detail.remainingPending - totalEntered;
    final isOverReturn = remainingAfter < 0;
    final needsReason = damaged > 0 || lost > 0 || shortage > 0;
    final lockedMode = m.lockedBillingMode ?? BillingMode.receivedQty;
    final labourEarned = _computeExpectedLabourPaise(
      issue: m,
      good: good,
      damaged: damaged,
    );

    final previouslySettled =
        view.returnedGoodQty +
        view.returnedDamagedQty +
        view.lostQty +
        view.shortageQty;

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.stockSettlementHeading,
        // Save stays pinned at the bottom while entering quantities.
        bottomAction: detail.remainingPending > 0
            ? AppButton(
                label: l10n.stockConfirmSaveReturnAction,
                icon: AppIcons.confirm,
                isExpanded: true,
                isLoading: _saving,
                onPressed: (!isOverReturn && totalEntered > 0 && !_saving)
                    ? _submit
                    : null,
              )
            : null,
        body: Form(
          key: _formKey,
          autovalidateMode: _submittedOnce
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              // Parent Issue Summary Header Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeading(
                      '${view.workerName ?? '-'} • ${view.processName ?? '-'}',
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      '${view.lotNumber} • ${view.designName} • ${view.colourName}',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label: '${l10n.stockIssuedLabel}: ${m.quantity}',
                          tone: AppStatusTone.info,
                        ),
                        AppStatusBadge(
                          label:
                              '${l10n.stockPreviouslyReturnedLabel}: $previouslySettled',
                          tone: AppStatusTone.good,
                        ),
                        AppStatusBadge(
                          label:
                              '${l10n.stockRemainingPendingLabel}: ${detail.remainingPending}',
                          tone: detail.remainingPending > 0
                              ? AppStatusTone.pending
                              : AppStatusTone.good,
                          icon: AppIcons.pending,
                        ),
                        AppStatusBadge(
                          label:
                              '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                          tone: AppStatusTone.neutral,
                          icon: AppIcons.lock,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${DomainLabelLocalizer.billingMode(l10n, lockedMode)} • ${IstDateTimeHelper.formatIstDateTime(m.transactionAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),

              if (detail.remainingPending > 0) ...[
                const SizedBox(height: AppSpacing.md),

                // STEP 2: ENTER RETURN QUANTITIES + LIVE REMAINING INDICATOR
                AppCard(
                  borderColor: isOverReturn ? colorScheme.error : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Live Remaining Pending Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isOverReturn
                              ? semantic.damagedContainer
                              : (remainingAfter == 0
                                    ? semantic.goodStockContainer
                                    : semantic.pendingContainer),
                          borderRadius: AppRadius.mdBorder,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOverReturn
                                  ? AppIcons.error
                                  : (remainingAfter == 0
                                        ? AppIcons.successOutline
                                        : AppIcons.pending),
                              size: 20,
                              color: isOverReturn
                                  ? semantic.damaged
                                  : (remainingAfter == 0
                                        ? semantic.goodStock
                                        : semantic.pending),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppText(
                                isOverReturn
                                    ? l10n.stockOverReturnErrorLive
                                    : l10n.stockLiveRemainingAfterReturn,
                                variant: AppTextVariant.bodySmall,
                                fontWeight: FontWeight.w600,
                                color: isOverReturn
                                    ? semantic.damaged
                                    : (remainingAfter == 0
                                          ? semantic.goodStock
                                          : semantic.pending),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppText(
                              isOverReturn
                                  ? '$totalEntered / ${detail.remainingPending}'
                                  : '$remainingAfter ${l10n.piecesUnit}',
                              variant: AppTextVariant.numeric,
                              fontWeight: FontWeight.w700,
                              color: isOverReturn
                                  ? semantic.damaged
                                  : (remainingAfter == 0
                                        ? semantic.goodStock
                                        : semantic.pending),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Flexible 2-Stage Return Mode selector (Rule 2 & Rule 6)
                      AppRadio<ProductionReturnMode>(
                        groupValue: _returnMode,
                        onChanged: (mode) {
                          _dirty.markDirty();
                          if (mode != null) {
                            setState(() {
                              _returnMode = mode;
                              _submitError = null;
                            });
                          }
                        },
                        options: [
                          AppRadioOption(
                            value: ProductionReturnMode.immediateInspection,
                            label: l10n.prodHistoryReturnModeImmediate,
                          ),
                          AppRadioOption(
                            value: ProductionReturnMode.pendingInspection,
                            label: l10n.prodHistoryReturnModePending,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ActionChip(
                            avatar: Icon(
                              AppIcons.doneAll,
                              size: 16,
                              color: semantic.goodStock,
                            ),
                            label: Text(
                              '${l10n.stockFillAllRemaining} (${detail.remainingPending})',
                            ),
                            onPressed: () =>
                                _fillAllGood(detail.remainingPending),
                          ),
                          if (detail.remainingPending >= 4)
                            ActionChip(
                              label: Text(
                                '${l10n.stockShortcutHalf} (${detail.remainingPending ~/ 2})',
                              ),
                              onPressed: () => _setGoodQtyClamped(
                                detail.remainingPending ~/ 2,
                                detail.remainingPending -
                                    (damaged + lost + shortage),
                              ),
                            ),
                          if (detail.remainingPending >= 10)
                            ActionChip(
                              label: const Text('+10'),
                              onPressed: () => _setGoodQtyClamped(
                                good + 10,
                                detail.remainingPending -
                                    (damaged + lost + shortage),
                              ),
                            ),
                          if (detail.remainingPending >= 25)
                            ActionChip(
                              label: const Text('+25'),
                              onPressed: () => _setGoodQtyClamped(
                                good + 25,
                                detail.remainingPending -
                                    (damaged + lost + shortage),
                              ),
                            ),
                          if ((damaged + lost + shortage) > 0 &&
                              remainingAfter > 0)
                            ActionChip(
                              avatar: Icon(
                                AppIcons.autoFill,
                                size: 16,
                                color: semantic.goodStock,
                              ),
                              label: Text(
                                '${l10n.stockFillRemainingGood} (${detail.remainingPending - (damaged + lost + shortage)})',
                              ),
                              onPressed: () => _setGoodQtyClamped(
                                detail.remainingPending -
                                    (damaged + lost + shortage),
                                detail.remainingPending,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      // Good Returned (Primary Green)
                      AppTextField(
                        fieldKey: _goodFieldKey,
                        controller: _goodCtrl,
                        label: l10n.stockGoodReturnQtyLabel,
                        prefixIcon: AppIcons.successOutline,
                        suffixText: l10n.piecesUnit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTypography.tabular(
                          Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: semantic.goodStock,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        validator: ValidationLocalizer.wrap(
                          l10n,
                          (v) => AppValidators.nonNegativeQuantityValidator(v),
                        ),
                        onChanged: (_) => setState(() => _submitError = null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Damaged Returned (Red)
                      AppTextField(
                        fieldKey: _damagedFieldKey,
                        controller: _damagedCtrl,
                        label: l10n.stockDamagedReturnQtyLabel,
                        prefixIcon: AppIcons.damaged,
                        suffixText: l10n.piecesUnit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTypography.tabular(
                          Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: damaged > 0 ? semantic.damaged : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        validator: ValidationLocalizer.wrap(
                          l10n,
                          (v) => AppValidators.nonNegativeQuantityValidator(v),
                        ),
                        onChanged: (_) => setState(() => _submitError = null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Lost vs Shortage clearly separated with helper text
                      AppTextField(
                        fieldKey: _lostFieldKey,
                        controller: _lostCtrl,
                        label: l10n.stockLostQtyLabel,
                        helperText: l10n.stockLostHelper,
                        prefixIcon: AppIcons.help,
                        suffixText: l10n.piecesUnit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTypography.tabular(
                          Theme.of(context).textTheme.titleMedium!,
                        ),
                        validator: ValidationLocalizer.wrap(
                          l10n,
                          (v) => AppValidators.nonNegativeQuantityValidator(v),
                        ),
                        onChanged: (_) => setState(() => _submitError = null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        fieldKey: _shortageFieldKey,
                        controller: _shortageCtrl,
                        label: l10n.stockShortageQtyLabel,
                        helperText: l10n.stockShortageHelper,
                        prefixIcon: AppIcons.remove,
                        suffixText: l10n.piecesUnit,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: AppTypography.tabular(
                          Theme.of(context).textTheme.titleMedium!,
                        ),
                        validator: ValidationLocalizer.wrap(
                          l10n,
                          (v) => AppValidators.nonNegativeQuantityValidator(v),
                        ),
                        onChanged: (_) => setState(() => _submitError = null),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        fieldKey: _reasonFieldKey,
                        controller: _reasonCtrl,
                        focusNode: _reasonFocus,
                        label: l10n.stockSettlementReasonLabel,
                        maxLines: 2,
                        maxLength: ValidationLimits.maxNotesLength,
                        validator: (v) {
                          if (needsReason && (v == null || v.trim().isEmpty)) {
                            return l10n.stockSettlementReasonRequiredError;
                          }
                          return ValidationLocalizer.localize(
                            l10n,
                            AppValidators.maxLengthValidator(
                              v,
                              maxLength: ValidationLimits.maxNotesLength,
                            ),
                          );
                        },
                        onChanged: (_) => setState(() => _submitError = null),
                      ),
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          initiallyExpanded: _showAdvanced,
                          onExpansionChanged: (v) =>
                              setState(() => _showAdvanced = v),
                          leading: const Icon(AppIcons.time, size: 18),
                          title: AppText(
                            '${l10n.stockTransactionDateTimeLabel} / ${l10n.stockNotesLabel}',
                            variant: AppTextVariant.label,
                          ),
                          children: [
                            const SizedBox(height: AppSpacing.sm),
                            AppDatePicker(
                              label: l10n.stockTransactionDateTimeLabel,
                              selectedUtcMillis: _transactionAtUtc,
                              includeTime: true,
                              onDateSelectedUtcMillis: (utc) =>
                                  _edit(() => _transactionAtUtc = utc),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppTextField(
                              fieldKey: _notesFieldKey,
                              controller: _notesCtrl,
                              label: l10n.stockNotesLabel,
                              maxLines: 2,
                              maxLength: ValidationLimits.maxNotesLength,
                              validator: ValidationLocalizer.wrap(
                                l10n,
                                (v) => AppValidators.maxLengthValidator(
                                  v,
                                  maxLength: ValidationLimits.maxNotesLength,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // STEP 3: CONSEQUENCES & LABOUR IMPACT SUMMARY + STEP 4 SAVE
                AppCard(
                  color: colorScheme.surfaceContainer,
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeading(
                        l10n.stockConsequencesTitle,
                        level: AppHeadingLevel.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (good > 0)
                        _ImpactLine(
                          icon: AppIcons.successOutline,
                          color: semantic.goodStock,
                          label: l10n.stockConsequenceGood,
                          value: '+$good ${l10n.piecesUnit}',
                        ),
                      if (damaged > 0)
                        _ImpactLine(
                          icon: AppIcons.damaged,
                          color: semantic.damaged,
                          label: l10n.stockConsequenceDamaged,
                          value: '+$damaged ${l10n.piecesUnit}',
                        ),
                      if (lost > 0)
                        _ImpactLine(
                          icon: AppIcons.help,
                          color: semantic.advanceCredit,
                          label: l10n.stockConsequenceLost,
                          value: '$lost ${l10n.piecesUnit}',
                        ),
                      if (shortage > 0)
                        _ImpactLine(
                          icon: AppIcons.remove,
                          color: semantic.advanceCredit,
                          label: l10n.stockConsequenceShortage,
                          value: '$shortage ${l10n.piecesUnit}',
                        ),
                      _ImpactLine(
                        icon: AppIcons.pending,
                        color: remainingAfter > 0
                            ? semantic.pending
                            : semantic.goodStock,
                        label: l10n.stockConsequencePending,
                        value:
                            '${remainingAfter < 0 ? 0 : remainingAfter} ${l10n.piecesUnit}',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Divider(),
                      ),
                      if (lockedMode == BillingMode.givenQty)
                        AppText(
                          l10n.stockConsequenceLabourAlreadyGiven,
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        )
                      else if (labourEarned > 0)
                        _ImpactLine(
                          icon: AppIcons.accounting,
                          color: semantic.goodStock,
                          label: l10n.stockConsequenceLabourEarned,
                          value: MoneyFormatter.formatPaise(labourEarned),
                        )
                      else
                        AppText(
                          l10n.stockConsequenceLabourNone,
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      if (_submitError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppStatusBadge(
                          label: _submitError!,
                          tone: AppStatusTone.damaged,
                          icon: AppIcons.error,
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Existing child settlements history (with localized movement labels!)
              if (detail.childSettlements.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                AppHeading(l10n.stockDetailsHeading, level: AppHeadingLevel.h3),
                const SizedBox(height: AppSpacing.sm),
                for (final child in detail.childSettlements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppStatusBadge(
                                  label: DomainLabelLocalizer.movementType(
                                    l10n,
                                    child.movement.movementType,
                                  ),
                                  tone: DomainLabelLocalizer.movementTone(
                                    child.movement.movementType,
                                  ),
                                ),
                                if (child.movement.reason != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    child.movement.reason!,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.xs),
                                AppText(
                                  IstDateTimeHelper.formatIstDateTime(
                                    child.movement.transactionAt,
                                    locale: localeCode,
                                  ),
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          if (child.isReversed)
                            AppStatusBadge(
                              label: l10n.stockReversedBadge,
                              tone: AppStatusTone.neutral,
                            )
                          else
                            AppText(
                              '${child.movement.quantity} ${l10n.piecesUnit}',
                              variant: AppTextVariant.numeric,
                              fontWeight: FontWeight.w700,
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, _ReturnSuccessInfo info) {
    final l10n = context.l10n;
    final semantic = context.semanticColors;

    return AppScaffold(
      title: l10n.stockSettlementHeading,
      body: ListView(
        children: [
          AppCard(
            borderColor: semantic.goodStock.withValues(alpha: 0.45),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: semantic.goodStockContainer,
                      borderRadius: AppRadius.fullBorder,
                    ),
                    child: Icon(
                      AppIcons.success,
                      color: semantic.goodStock,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.stockReturnSuccessTitle,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '${info.workerName} • ${info.processName} • ${info.lotNumber} • ${info.designName} • ${info.colourName}',
                  variant: AppTextVariant.bodySmall,
                  textAlign: TextAlign.center,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (info.goodQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockGoodReturnedLabel}: ${info.goodQty}',
                        tone: AppStatusTone.good,
                      ),
                    if (info.damagedQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockDamagedBucketLabel}: ${info.damagedQty}',
                        tone: AppStatusTone.damaged,
                      ),
                    if (info.lostQty > 0)
                      AppStatusBadge(
                        label: '${l10n.stockLostLabel}: ${info.lostQty}',
                        tone: AppStatusTone.info,
                      ),
                    if (info.shortageQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.stockShortageLabel}: ${info.shortageQty}',
                        tone: AppStatusTone.info,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  elevated: false,
                  color: info.updatedPending == 0
                      ? semantic.goodStockContainer.withValues(alpha: 0.55)
                      : semantic.pendingContainer.withValues(alpha: 0.55),
                  child: AppActionRow(
                    content: AppText(
                      l10n.stockReturnUpdatedPendingLabel,
                      fontWeight: FontWeight.w600,
                    ),
                    actions: [
                      AppStatusBadge(
                        label: info.updatedPending == 0
                            ? l10n.stockReturnFullySettledBadge
                            : '${info.updatedPending} ${l10n.piecesUnit}',
                        tone: info.updatedPending == 0
                            ? AppStatusTone.good
                            : AppStatusTone.pending,
                      ),
                    ],
                  ),
                ),
                if (info.labourEarnedPaise > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _ImpactLine(
                    icon: AppIcons.accounting,
                    color: semantic.goodStock,
                    label: l10n.stockConsequenceLabourEarned,
                    value: MoneyFormatter.formatPaise(info.labourEarnedPaise),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.slipShareReturnAction,
                  icon: AppIcons.share,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: () async {
                    final slip = await SlipBuilderHelper.buildReturnQcSlip(
                      referenceId:
                          'RET-${widget.issueId.length > 6 ? widget.issueId.substring(0, 6).toUpperCase() : widget.issueId.toUpperCase()}',
                      lotNumber: info.lotNumber,
                      designName: info.designName,
                      colourName: info.colourName,
                      processName: info.processName,
                      workerName: info.workerName,
                      goodQty: info.goodQty,
                      damagedQty: info.damagedQty,
                      lostQty: info.lostQty,
                      shortageQty: info.shortageQty,
                      labourEarnedPaise: info.labourEarnedPaise,
                      transactionAtUtcMillis: _transactionAtUtc,
                      notes: _notesCtrl.text,
                    );
                    if (context.mounted) {
                      await SlipShareSheet.show(context, slip);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                if (info.goodQty > 0) ...[
                  AppButton(
                    label: l10n.stockIssueNextProcessAction,
                    icon: AppIcons.stockIssue,
                    isExpanded: true,
                    onPressed: () => context.pushReplacement(
                      RoutePaths.stockIssue(
                        designColourId: info.designColourId,
                      ),
                    ),
                  ),
                  if (_otherActiveProcesses.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final proc in _otherActiveProcesses.take(4))
                          ActionChip(
                            avatar: const Icon(AppIcons.stockIssue, size: 16),
                            label: Text(proc.name),
                            onPressed: () => context.pushReplacement(
                              RoutePaths.stockIssue(
                                designColourId: info.designColourId,
                                processId: proc.id,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppButton(
                  label: l10n.stockReceiveAnotherReturnAction,
                  icon: AppIcons.receiveReturn,
                  variant: info.goodQty > 0
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  isExpanded: true,
                  onPressed: _receiveAnother,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.stockDetailsHeading,
                  variant: AppButtonVariant.outlined,
                  isExpanded: true,
                  onPressed: () => setState(() => _successInfo = null),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: l10n.actionDone,
                  variant: AppButtonVariant.text,
                  isExpanded: true,
                  onPressed: () => context.pop(true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _ReturnSuccessInfo {
  const _ReturnSuccessInfo({
    required this.designColourId,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    required this.workerName,
    required this.processName,
    required this.goodQty,
    required this.damagedQty,
    required this.lostQty,
    required this.shortageQty,
    required this.updatedPending,
    required this.labourEarnedPaise,
  });

  final String designColourId;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String workerName;
  final String processName;
  final int goodQty;
  final int damagedQty;
  final int lostQty;
  final int shortageQty;
  final int updatedPending;
  final int labourEarnedPaise;
}

final class _ImpactLine extends StatelessWidget {
  const _ImpactLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: AppText(label, variant: AppTextVariant.bodySmall)),
          const SizedBox(width: AppSpacing.sm),
          AppText(
            value,
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ],
      ),
    );
  }
}
