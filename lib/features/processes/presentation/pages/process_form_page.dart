import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Create or edit a dynamic production process.
final class ProcessFormPage extends StatefulWidget {
  const ProcessFormPage({super.key, this.processId});

  final String? processId;

  bool get isEdit => processId != null;

  @override
  State<ProcessFormPage> createState() => _ProcessFormPageState();
}

final class _ProcessFormPageState extends State<ProcessFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _descFieldKey = GlobalKey<FormFieldState<String>>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _descFocus = FocusNode();
  final _repository = getIt<ProcessRepository>();

  // Uses sentinel 'GLOBAL' in dropdown because DropdownButtonFormField null value shows hint.
  String _billingChoice = 'GLOBAL';
  bool _includeDamaged = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _submittedOnce = false;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final detail = await _repository.getProcessDetail(widget.processId!);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _isLoading = false;
          _loadError = 'Process not found.';
        });
        return;
      }
      final proc = detail.process;
      _nameCtrl.text = proc.name;
      _descCtrl.text = proc.description ?? '';
      _billingChoice = proc.billingModeOverride?.dbValue ?? 'GLOBAL';
      _includeDamaged = proc.includeDamagedInLabour;
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _nameFocus.dispose();
    _descFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _nameFieldKey, focusNode: _nameFocus),
        ValidatedFieldAnchor(fieldKey: _descFieldKey, focusNode: _descFocus),
      ],
    );
    if (!valid) return;
    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final override = _billingChoice == 'GLOBAL'
        ? null
        : ProcessBillingModeOverride.fromDbValue(_billingChoice);

    try {
      if (widget.isEdit) {
        await _repository.updateProcess(
          processId: widget.processId!,
          name: _nameCtrl.text,
          description: _descCtrl.text,
          billingModeOverride: override,
          includeDamagedInLabour: _includeDamaged,
        );
      } else {
        await _repository.createProcess(
          name: _nameCtrl.text,
          description: _descCtrl.text,
          billingModeOverride: override,
          includeDamagedInLabour: _includeDamaged,
        );
      }
      if (mounted) {
        context.pop(true);
      }
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = ValidationLocalizer.localizeDomainException(
          context.l10n,
          e,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = widget.isEdit
        ? l10n.processEditAction
        : l10n.processCreateAction;

    if (_isLoading) {
      return AppScaffold(title: title, body: const AppLoader());
    }
    if (_loadError != null) {
      return AppScaffold(
        title: title,
        body: AppErrorView(
          title: l10n.errorUnexpected,
          message: _loadError,
          retryLabel: l10n.actionRetry,
          onRetry: _loadExisting,
        ),
      );
    }

    return AppScaffold(
      title: title,
      body: Form(
        key: _formKey,
        autovalidateMode: _submittedOnce
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    fieldKey: _nameFieldKey,
                    controller: _nameCtrl,
                    focusNode: _nameFocus,
                    label: l10n.processNameLabel,
                    prefixIcon: Icons.precision_manufacturing_outlined,
                    textInputAction: TextInputAction.next,
                    maxLength: ValidationLimits.maxShortNameLength,
                    onChanged: (_) {
                      if (_submitError != null) {
                        setState(() => _submitError = null);
                      }
                    },
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nameValidator(
                        v,
                        maxLength: ValidationLimits.maxShortNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey: _descFieldKey,
                    controller: _descCtrl,
                    focusNode: _descFocus,
                    label: l10n.processDescriptionLabel,
                    maxLines: 3,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxNotesLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: l10n.processBillingOverrideLabel,
                    value: _billingChoice,
                    items: const ['GLOBAL', 'RECEIVED_QTY', 'GIVEN_QTY'],
                    itemLabelBuilder: (item) => switch (item) {
                      'RECEIVED_QTY' => l10n.billingModeReceivedQty,
                      'GIVEN_QTY' => l10n.billingModeGivenQty,
                      _ => l10n.processBillingInheritGlobal,
                    },
                    onChanged: (v) {
                      if (v != null) setState(() => _billingChoice = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSwitch(
                    label: l10n.processIncludeDamagedLabel,
                    value: _includeDamaged,
                    onChanged: (v) => setState(() => _includeDamaged = v),
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
                    icon: Icons.check,
                    isExpanded: true,
                    isLoading: _isSaving,
                    onPressed: _save,
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
