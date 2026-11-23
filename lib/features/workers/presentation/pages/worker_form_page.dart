import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Create or edit a worker (`members` table).
final class WorkerFormPage extends StatefulWidget {
  const WorkerFormPage({super.key, this.workerId});

  final String? workerId;

  bool get isEdit => workerId != null;

  @override
  State<WorkerFormPage> createState() => _WorkerFormPageState();
}

final class _WorkerFormPageState extends State<WorkerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameFieldKey = GlobalKey<FormFieldState<String>>();
  final _phoneFieldKey = GlobalKey<FormFieldState<String>>();
  final _addressFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _notesFocus = FocusNode();

  final _repository = getIt<WorkerRepository>();

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
      final detail = await _repository.getWorkerDetail(widget.workerId!);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _isLoading = false;
          _loadError = context.l10n.validationWorkerNotFound;
        });
        return;
      }
      final w = detail.worker;
      _nameCtrl.text = w.name;
      _phoneCtrl.text = w.phone ?? '';
      _addressCtrl.text = w.address ?? '';
      _notesCtrl.text = w.notes ?? '';
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
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _addressFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }
    final isValid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(fieldKey: _nameFieldKey, focusNode: _nameFocus),
        ValidatedFieldAnchor(fieldKey: _phoneFieldKey, focusNode: _phoneFocus),
        ValidatedFieldAnchor(
          fieldKey: _addressFieldKey,
          focusNode: _addressFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!isValid) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      if (widget.isEdit) {
        await _repository.updateWorker(
          workerId: widget.workerId!,
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          notes: _notesCtrl.text,
        );
      } else {
        await _repository.createWorker(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          address: _addressCtrl.text,
          notes: _notesCtrl.text,
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
        ? l10n.workerEditAction
        : l10n.workerCreateAction;

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
                    label: l10n.workerNameLabel,
                    prefixIcon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                    maxLength: ValidationLimits.maxPersonNameLength,
                    onChanged: (_) {
                      if (_submitError != null) {
                        setState(() => _submitError = null);
                      }
                    },
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nameValidator(
                        v,
                        maxLength: ValidationLimits.maxPersonNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey: _phoneFieldKey,
                    controller: _phoneCtrl,
                    focusNode: _phoneFocus,
                    label: l10n.workerPhoneLabel,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (_submitError != null) {
                        setState(() => _submitError = null);
                      }
                    },
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.mobileNumberValidator(v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey: _addressFieldKey,
                    controller: _addressCtrl,
                    focusNode: _addressFocus,
                    label: l10n.workerAddressLabel,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                    maxLength: ValidationLimits.maxAddressLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxAddressLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    fieldKey: _notesFieldKey,
                    controller: _notesCtrl,
                    focusNode: _notesFocus,
                    label: l10n.workerNotesLabel,
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
