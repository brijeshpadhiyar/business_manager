import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Audited worker ledger adjustment screen (CREDIT or DEBIT with mandatory reason).
final class WorkerAdjustmentFormPage extends StatefulWidget {
  const WorkerAdjustmentFormPage({super.key, required this.workerId});

  final String workerId;

  @override
  State<WorkerAdjustmentFormPage> createState() =>
      _WorkerAdjustmentFormPageState();
}

final class _WorkerAdjustmentFormPageState
    extends State<WorkerAdjustmentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _repo = getIt<AccountingRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  WorkerAdjustmentType _type = WorkerAdjustmentType.credit;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
  bool _saving = false;
  String? _submitError;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int? _parsePaise(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null || parsed <= 0) return null;
    return (parsed * 100).round();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving) return;
    final paise = _parsePaise(_amountCtrl.text);
    if (paise == null) return;

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await _repo.recordAdjustment(
        workerId: widget.workerId,
        adjustmentType: _type,
        amountPaise: paise,
        reason: _reasonCtrl.text,
        transactionAtUtcMillis: _transactionAtUtc,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(
          context,
          context.l10n.accountingAdjustmentSaved,
        );
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.message;
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
    return AppScaffold(
      title: l10n.accountingAddAdjustmentAction,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<WorkerAdjustmentType>(
                    label: l10n.accountingAdjustmentTypeLabel,
                    value: _type,
                    items: const [
                      WorkerAdjustmentType.credit,
                      WorkerAdjustmentType.debit,
                    ],
                    itemLabelBuilder: (t) => t == WorkerAdjustmentType.credit
                        ? l10n.accountingAdjustmentCredit
                        : l10n.accountingAdjustmentDebit,
                    onChanged: (v) {
                      if (v != null) setState(() => _type = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _amountCtrl,
                    label: l10n.accountingAmountLabel,
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => _parsePaise(v ?? '') == null
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDatePicker(
                    label: l10n.stockTransactionDateTimeLabel,
                    selectedUtcMillis: _transactionAtUtc,
                    includeTime: true,
                    onDateSelectedUtcMillis: (utc) =>
                        setState(() => _transactionAtUtc = utc),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _reasonCtrl,
                    label: l10n.accountingAdjustmentReasonLabel,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
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
        ),
      ),
    );
  }
}
