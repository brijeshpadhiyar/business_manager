import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Partial or complete return & settlement screen linked to an original ISSUE.
final class StockSettlementPage extends StatefulWidget {
  const StockSettlementPage({super.key, required this.issueId});

  final String issueId;

  @override
  State<StockSettlementPage> createState() => _StockSettlementPageState();
}

final class _StockSettlementPageState extends State<StockSettlementPage> {
  final _formKey = GlobalKey<FormState>();
  final _goodCtrl = TextEditingController(text: '0');
  final _damagedCtrl = TextEditingController(text: '0');
  final _lostCtrl = TextEditingController(text: '0');
  final _shortageCtrl = TextEditingController(text: '0');
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _repo = getIt<StockMovementRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  OpenIssueSummary? _detail;
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  String? _submitError;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _goodCtrl.dispose();
    _damagedCtrl.dispose();
    _lostCtrl.dispose();
    _shortageCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final detail = await _repo.getIssueDetail(widget.issueId);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _loading = false;
          _loadError = 'Issue record not found.';
        });
        return;
      }
      setState(() {
        _detail = detail;
        _goodCtrl.text = '${detail.remainingPending}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  int _qtyOf(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving || _detail == null) return;
    final l10n = context.l10n;

    final good = _qtyOf(_goodCtrl);
    final damaged = _qtyOf(_damagedCtrl);
    final lost = _qtyOf(_lostCtrl);
    final shortage = _qtyOf(_shortageCtrl);
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

    setState(() {
      _saving = true;
      _submitError = null;
    });

    try {
      await _repo.recordSettlement(
        parentIssueId: widget.issueId,
        goodQuantity: good,
        damagedQuantity: damaged,
        lostQuantity: lost,
        shortageQuantity: shortage,
        transactionAtUtcMillis: _transactionAtUtc,
        reason: _reasonCtrl.text,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.stockSettlementSuccess);
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = switch (e.code) {
          'exceeds_pending_quantity' => l10n.stockSettlementTotalExceedsError,
          'settlement_empty' => l10n.stockSettlementEmptyError,
          'reason_required' => l10n.stockSettlementReasonRequiredError,
          _ => e.message,
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    if (_loading) {
      return AppScaffold(
        title: l10n.stockSettlementHeading,
        body: const AppLoader(),
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

    final detail = _detail!;
    final view = detail.issueView;
    final m = view.movement;

    return AppScaffold(
      title: l10n.stockSettlementHeading,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    '${view.lotNumber} • ${view.designName} • ${view.colourName}',
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    '${view.processName ?? '-'} • ${view.workerName ?? '-'}',
                    variant: AppTextVariant.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(
                        label: '${l10n.stockIssuedLabel}: ${m.quantity}',
                        tone: AppStatusTone.info,
                      ),
                      AppStatusBadge(
                        label:
                            '${l10n.stockGoodReturnedLabel}: ${view.returnedGoodQty}',
                        tone: AppStatusTone.good,
                      ),
                      AppStatusBadge(
                        label:
                            '${l10n.stockRemainingPendingLabel}: ${detail.remainingPending}',
                        tone: detail.remainingPending > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.good,
                      ),
                      AppStatusBadge(
                        label:
                            '${MoneyFormatter.formatPaise(m.appliedRatePaise)} ${l10n.ratesPerPieceSuffix}',
                        tone: AppStatusTone.neutral,
                        icon: Icons.lock_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    l10n.stockInheritedRateNotice,
                    variant: AppTextVariant.bodySmall,
                  ),
                ],
              ),
            ),
            if (detail.remainingPending > 0) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppDatePicker(
                      label: l10n.stockTransactionDateTimeLabel,
                      selectedUtcMillis: _transactionAtUtc,
                      includeTime: true,
                      onDateSelectedUtcMillis: (utc) =>
                          setState(() => _transactionAtUtc = utc),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _goodCtrl,
                            label: l10n.stockGoodReturnQtyLabel,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _damagedCtrl,
                            label: l10n.stockDamagedReturnQtyLabel,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _lostCtrl,
                            label: l10n.stockLostQtyLabel,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: _shortageCtrl,
                            label: l10n.stockShortageQtyLabel,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _reasonCtrl,
                      label: l10n.stockSettlementReasonLabel,
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _notesCtrl,
                      label: l10n.stockNotesLabel,
                      maxLines: 2,
                    ),
                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(
                        _submitError!,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.actionSave,
                      icon: Icons.check_rounded,
                      isExpanded: true,
                      isLoading: _saving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ],
            if (detail.childSettlements.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppHeading(l10n.stockDetailsHeading, level: AppHeadingLevel.h3),
              const SizedBox(height: AppSpacing.sm),
              for (final child in detail.childSettlements)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                child.movement.movementType.dbValue,
                                fontWeight: FontWeight.w700,
                              ),
                              if (child.movement.reason != null)
                                AppText(
                                  child.movement.reason!,
                                  variant: AppTextVariant.bodySmall,
                                ),
                              AppText(
                                IstDateTimeHelper.formatIstDateTime(
                                  child.movement.transactionAt,
                                  locale: localeCode,
                                ),
                                variant: AppTextVariant.bodySmall,
                              ),
                            ],
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }
}
