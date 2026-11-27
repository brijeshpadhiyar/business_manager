import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Create or edit a Party / Buyer / Job-Work Client.
final class PartyFormPage extends StatefulWidget {
  const PartyFormPage({super.key, this.partyId});

  final String? partyId;

  bool get isEdit => partyId != null;

  @override
  State<PartyFormPage> createState() => _PartyFormPageState();
}

final class _PartyFormPageState extends State<PartyFormPage> {
  final _repo = getIt<PartyRepository>();
  final _formKey = GlobalKey<FormState>();
  final _dirty = AppFormDirtyTracker();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _openingCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  PartyType _partyType = PartyType.both;
  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([
      _nameCtrl,
      _phoneCtrl,
      _addressCtrl,
      _gstinCtrl,
      _openingCtrl,
      _notesCtrl,
    ]);
    _load();
  }

  Future<void> _load() async {
    if (!widget.isEdit) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final party = await _repo.getPartyById(widget.partyId!);
      if (!mounted) return;
      if (party == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'party_not_found';
        });
        return;
      }
      _nameCtrl.text = party.name;
      _phoneCtrl.text = party.phone ?? '';
      _addressCtrl.text = party.address ?? '';
      _gstinCtrl.text = party.gstin ?? '';
      if (party.openingBalancePaise != 0) {
        _openingCtrl.text = (party.openingBalancePaise / 100.0).toStringAsFixed(
          2,
        );
      }
      _notesCtrl.text = party.notes ?? '';
      _partyType = party.partyType;
      _isActive = party.isActive;
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

  @override
  void dispose() {
    _dirty.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _gstinCtrl.dispose();
    _openingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final rawOpening = _openingCtrl.text.trim();
    var openingPaise = 0;
    if (rawOpening.isNotEmpty) {
      final isNegative = rawOpening.startsWith('-');
      final absText = isNegative ? rawOpening.substring(1) : rawOpening;
      final parsed = AppValidators.parseRupeesToPaiseExact(
        absText,
        allowZero: true,
      ).paise;
      if (parsed == null) {
        AppFeedback.showError(context, l10n.validationInvalidNumber);
        return;
      }
      openingPaise = isNegative ? -parsed : parsed;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.isEdit) {
        await _repo.updateParty(
          partyId: widget.partyId!,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          partyType: _partyType,
          gstin: _gstinCtrl.text,
          openingBalancePaise: openingPaise,
          notes: _notesCtrl.text,
          isActive: _isActive,
        );
      } else {
        await _repo.createParty(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          partyType: _partyType,
          gstin: _gstinCtrl.text,
          openingBalancePaise: openingPaise,
          notes: _notesCtrl.text,
        );
      }
      if (!mounted) return;
      _dirty.reset();
      AppFeedback.showSuccess(context, l10n.partySavedSuccess);
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
        title: widget.isEdit ? l10n.partyEditAction : l10n.partyAddAction,
        contentWidth: AppContentWidth.narrow,
        bottomAction: (_isLoading || _loadError != null)
            ? null
            : AppStickyActionBar(
                child: AppButton(
                  label: l10n.actionSave,
                  icon: AppIcons.save,
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
                          AppTextField(
                            controller: _nameCtrl,
                            label: l10n.partyNameLabel,
                            prefixIcon: AppIcons.party,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.nameValidator(v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppText(
                            l10n.partyTypeLabel,
                            variant: AppTextVariant.label,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppChipGroup<PartyType>(
                            items: PartyType.values,
                            value: _partyType,
                            onChanged: (t) {
                              _dirty.markDirty();
                              setState(() => _partyType = t);
                            },
                            itemLabelBuilder: (t) => switch (t) {
                              PartyType.buyer => l10n.partyTypeBuyer,
                              PartyType.jobClient => l10n.partyTypeJobClient,
                              PartyType.both => l10n.partyTypeBoth,
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _phoneCtrl,
                            label: l10n.partyPhoneLabel,
                            prefixIcon: AppIcons.phone,
                            keyboardType: TextInputType.phone,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.mobileNumberValidator(v),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _addressCtrl,
                            label: l10n.partyAddressLabel,
                            prefixIcon: AppIcons.location,
                            maxLines: 2,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _gstinCtrl,
                            label: l10n.partyGstinLabel,
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _openingCtrl,
                            label: l10n.partyOpeningBalanceLabel,
                            prefixIcon: AppIcons.rupee,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _notesCtrl,
                            label: l10n.lotNotesLabel,
                            prefixIcon: AppIcons.notes,
                            maxLines: 2,
                          ),
                          if (widget.isEdit) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppSwitch(
                              label: l10n.partyActiveLabel,
                              value: _isActive,
                              onChanged: (v) {
                                _dirty.markDirty();
                                setState(() => _isActive = v);
                              },
                            ),
                          ],
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
