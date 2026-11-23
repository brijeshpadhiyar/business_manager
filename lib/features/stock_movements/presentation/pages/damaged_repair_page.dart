import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Audited Damaged-to-Good repair adjustment screen.
final class DamagedRepairPage extends StatefulWidget {
  const DamagedRepairPage({super.key});

  @override
  State<DamagedRepairPage> createState() => _DamagedRepairPageState();
}

final class _DamagedRepairPageState extends State<DamagedRepairPage> {
  final _formKey = GlobalKey<FormState>();
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _repo = getIt<StockMovementRepository>();
  final _clientRequestId = getIt<IdGenerator>().nextRequestId();

  List<DesignColourStockBalance> _damagedBalances = const [];
  String? _selectedColourId;
  int _transactionAtUtc = IstDateTimeHelper.nowUtcMillis();
  bool _loading = true;
  bool _saving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.getAllDesignColourBalances(onlyWithDamaged: true);
    if (!mounted) return;
    setState(() {
      _damagedBalances = items;
      _selectedColourId = items.isNotEmpty ? items.first.designColourId : null;
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_saving || _selectedColourId == null) return;
    final l10n = context.l10n;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;

    setState(() {
      _saving = true;
      _submitError = null;
    });
    try {
      await _repo.recordDamagedToGoodAdjustment(
        designColourId: _selectedColourId!,
        quantity: qty,
        reason: _reasonCtrl.text,
        transactionAtUtcMillis: _transactionAtUtc,
        notes: _notesCtrl.text,
        clientRequestId: _clientRequestId,
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.stockRepairSuccess);
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _submitError = e.code == 'exceeds_damaged_stock'
            ? l10n.stockRepairExceedsDamagedError
            : e.message;
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
    if (_loading) {
      return AppScaffold(
        title: l10n.stockRepairHeading,
        body: const AppLoader(),
      );
    }
    if (_damagedBalances.isEmpty) {
      return AppScaffold(
        title: l10n.stockRepairHeading,
        body: AppEmptyState(
          icon: Icons.verified_outlined,
          title: l10n.stockNoDamagedAvailable,
        ),
      );
    }

    final selected = _damagedBalances.firstWhere(
      (b) => b.designColourId == _selectedColourId,
    );

    return AppScaffold(
      title: l10n.stockRepairHeading,
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppDropdown<String>(
                    label: l10n.stockSelectColourLabel,
                    value: _selectedColourId,
                    items: _damagedBalances
                        .map((b) => b.designColourId)
                        .toList(),
                    itemLabelBuilder: (id) {
                      final b = _damagedBalances.firstWhere(
                        (e) => e.designColourId == id,
                      );
                      return '${b.lotNumber} • ${b.designName} • ${b.colourName} (${b.damagedBucket} ${l10n.stockDamagedBucketLabel})';
                    },
                    onChanged: (v) => setState(() => _selectedColourId = v),
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
                    controller: _qtyCtrl,
                    label: l10n.stockRepairQuantityLabel,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final q = int.tryParse(v?.trim() ?? '');
                      if (q == null || q <= 0) return l10n.stockInvalidQtyError;
                      if (q > selected.damagedBucket) {
                        return l10n.stockRepairExceedsDamagedError;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _reasonCtrl,
                    label: l10n.stockRepairReasonLabel,
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
