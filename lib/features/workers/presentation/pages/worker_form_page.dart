import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
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
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _repository = getIt<WorkerRepository>();

  bool _isLoading = false;
  bool _isSaving = false;
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
          _loadError = 'Worker not found.';
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;
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
      final l10n = context.l10n;
      setState(() {
        _isSaving = false;
        _submitError = switch (e.code) {
          'worker_name_required' => l10n.validationRequired,
          _ => e.message,
        };
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
        child: ListView(
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: _nameCtrl,
                    label: l10n.workerNameLabel,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _phoneCtrl,
                    label: l10n.workerPhoneLabel,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _addressCtrl,
                    label: l10n.workerAddressLabel,
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _notesCtrl,
                    label: l10n.workerNotesLabel,
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
