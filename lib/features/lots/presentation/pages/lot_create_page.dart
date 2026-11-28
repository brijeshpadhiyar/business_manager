import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_create_form_models.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_create_variant_cards.dart';
import 'package:business_manager/features/lots/presentation/widgets/visual_colour_picker_sheet.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Complete one-screen Lot Creation workflow.
final class LotCreatePage extends StatefulWidget {
  const LotCreatePage({super.key});

  @override
  State<LotCreatePage> createState() => _LotCreatePageState();
}

final class _LotCreatePageState extends State<LotCreatePage> {
  final _dirty = AppFormDirtyTracker();

  void _edit(VoidCallback fn) {
    _dirty.markDirty();
    setState(fn);
  }

  final _lotRepo = getIt<LotRepository>();
  final _processRepo = getIt<ProcessRepository>();
  final _workerRepo = getIt<WorkerRepository>();
  final _formKey = GlobalKey<FormState>();
  final _numberFieldKey = GlobalKey<FormFieldState<String>>();
  final _titleFieldKey = GlobalKey<FormFieldState<String>>();
  final _notesFieldKey = GlobalKey<FormFieldState<String>>();

  final _numberCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _numberFocus = FocusNode();
  final _titleFocus = FocusNode();
  final _notesFocus = FocusNode();

  bool _showInlineDesignForm = false;
  final _newDesignNameCtrl = TextEditingController();
  final _newDesignNotesCtrl = TextEditingController();
  final _newDesignPriceCtrl = TextEditingController();
  String? _inlineDesignError;

  List<String> _knownDesignNames = const [];
  String? _selectedKnownDesign;

  bool _useDesigns = true;
  int _txDateUtc = IstDateTimeHelper.nowUtcMillis();

  final List<DesignBlockState> _designs = [];
  final List<ColourVariantRowState> _colourOnlyVariants = [];

  List<ProcessEntity> _activeProcesses = const [];
  List<WorkerEntity> _activeWorkers = const [];
  final List<InitialLotProcessAssignmentInput> _initialAssignments = [];

  int _seq = 0;
  bool _submittedOnce = false;
  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _dirty.watch([_numberCtrl, _titleCtrl, _notesCtrl]);
    _loadDesignSuggestions();
  }

  Future<void> _loadDesignSuggestions() async {
    try {
      final results = await Future.wait([
        _lotRepo.getDistinctDesignNames(),
        _processRepo.getProcesses(isActiveFilter: true),
        _workerRepo.getWorkers(isActiveFilter: true),
      ]);
      if (!mounted) return;
      setState(() {
        _knownDesignNames = results[0] as List<String>;
        _activeProcesses = results[1] as List<ProcessEntity>;
        _activeWorkers = results[2] as List<WorkerEntity>;
      });
    } catch (e) {
      if (getIt.isRegistered<AppLogger>()) {
        getIt<AppLogger>().warning(
          'Lot create suggestion load failed',
          error: e,
        );
      }
    }
  }

  Future<void> _showAddInitialAssignmentSheet() async {
    final skuOptions = <({String designName, String colourName, int qty})>[
      if (_useDesigns)
        for (final d in _designs)
          for (final c in d.colours)
            (
              designName: d.designName,
              colourName: c.colourName,
              qty: c.quantity,
            )
      else
        for (final c in _colourOnlyVariants)
          (
            designName: kColourOnlyDesignSentinel,
            colourName: c.colourName,
            qty: c.quantity,
          ),
    ];
    final created = await showAddInitialLotAssignmentSheet(
      context,
      skuOptions: skuOptions,
      activeProcesses: _activeProcesses,
      activeWorkers: _activeWorkers,
    );
    if (created != null && mounted) {
      setState(() => _initialAssignments.add(created));
    }
  }

  @override
  void dispose() {
    _dirty.dispose();
    _numberCtrl.dispose();
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _numberFocus.dispose();
    _titleFocus.dispose();
    _notesFocus.dispose();
    _newDesignNameCtrl.dispose();
    _newDesignNotesCtrl.dispose();
    _newDesignPriceCtrl.dispose();
    for (final d in _designs) {
      d.dispose();
    }
    for (final c in _colourOnlyVariants) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalColoursCount => _useDesigns
      ? _designs.fold(0, (acc, d) => acc + d.colours.length)
      : _colourOnlyVariants.length;

  int get _totalQuantity => _useDesigns
      ? _designs.fold(0, (acc, d) => acc + d.totalQty)
      : _colourOnlyVariants.fold(0, (acc, c) => acc + c.quantity);

  int get _totalValuePaise => _useDesigns
      ? _designs.fold(0, (acc, d) => acc + d.totalValuePaise)
      : _colourOnlyVariants.fold(
          0,
          (acc, c) => acc + (c.quantity * c.unitPricePaise),
        );

  bool _hasDesignName(String name) {
    final lower = name.trim().toLowerCase();
    return _designs.any((d) => d.designName.trim().toLowerCase() == lower);
  }

  void _addExistingDesign(String name) {
    _dirty.markDirty();
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_hasDesignName(trimmed)) {
      setState(() {
        _inlineDesignError = context.l10n.lotDesignAlreadyAdded(trimmed);
      });
      return;
    }
    setState(() {
      _inlineDesignError = null;
      _submitError = null;
      _designs.add(
        DesignBlockState(id: 'design_${++_seq}', designName: trimmed),
      );
      _selectedKnownDesign = null;
    });
  }

  void _saveInlineNewDesign() {
    final cleanName = _newDesignNameCtrl.text.trim();
    if (cleanName.isEmpty) {
      setState(() => _inlineDesignError = context.l10n.lotEnterDesignName);
      return;
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength) {
      setState(() => _inlineDesignError = context.l10n.lotDesignNameTooLong);
      return;
    }
    if (_hasDesignName(cleanName)) {
      setState(
        () =>
            _inlineDesignError = context.l10n.lotDesignAlreadyAdded(cleanName),
      );
      return;
    }
    final parsedPrice = AppValidators.parseRupeesToPaiseExact(
      _newDesignPriceCtrl.text,
      isRequired: false,
      allowZero: true,
    );
    if (!parsedPrice.validation.isValid || parsedPrice.paise == null) {
      setState(
        () => _inlineDesignError = context.l10n.lotEnterValidDefaultPrice,
      );
      return;
    }
    final notes = _newDesignNotesCtrl.text.trim();
    setState(() {
      _designs.add(
        DesignBlockState(
          id: 'design_${++_seq}',
          designName: cleanName,
          notes: notes.isEmpty ? null : notes,
          defaultUnitPricePaise: parsedPrice.paise!,
        ),
      );
      if (!_knownDesignNames.any(
        (n) => n.toLowerCase() == cleanName.toLowerCase(),
      )) {
        _knownDesignNames = [..._knownDesignNames, cleanName]
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      }
      _newDesignNameCtrl.clear();
      _newDesignNotesCtrl.clear();
      _newDesignPriceCtrl.clear();
      _inlineDesignError = null;
      _showInlineDesignForm = false;
      _submitError = null;
    });
  }

  void _removeDesign(DesignBlockState design) {
    _dirty.markDirty();
    setState(() {
      _designs.remove(design);
      design.dispose();
    });
  }

  Future<void> _pickColoursForDesign(DesignBlockState design) async {
    _dirty.markDirty();
    final existingLower = design.colours
        .map((c) => c.colourName.trim().toLowerCase())
        .toSet();
    final picked = await VisualColourPickerSheet.show(
      context,
      title: context.l10n.lotSelectColoursForDesign(design.designName),
      existingColourNamesLower: existingLower,
      defaultUnitPricePaise: design.defaultUnitPricePaise,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() {
      _submitError = null;
      for (final item in picked) {
        if (design.colours.any(
          (c) =>
              c.colourName.trim().toLowerCase() ==
              item.colourName.trim().toLowerCase(),
        )) {
          continue;
        }
        design.colours.add(
          ColourVariantRowState(
            id: 'col_${++_seq}',
            colourName: item.colourName,
            colourHex: item.hexCode,
            initialQuantity: item.quantity,
            unitPricePaise: item.unitPricePaise,
          ),
        );
      }
    });
  }

  Future<void> _pickColoursForColourOnly() async {
    _dirty.markDirty();
    final existingLower = _colourOnlyVariants
        .map((c) => c.colourName.trim().toLowerCase())
        .toSet();
    final picked = await VisualColourPickerSheet.show(
      context,
      title: context.l10n.lotSelectColoursColourOnly,
      existingColourNamesLower: existingLower,
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() {
      _submitError = null;
      for (final item in picked) {
        if (_colourOnlyVariants.any(
          (c) =>
              c.colourName.trim().toLowerCase() ==
              item.colourName.trim().toLowerCase(),
        )) {
          continue;
        }
        _colourOnlyVariants.add(
          ColourVariantRowState(
            id: 'col_${++_seq}',
            colourName: item.colourName,
            colourHex: item.hexCode,
            initialQuantity: item.quantity,
            unitPricePaise: item.unitPricePaise,
          ),
        );
      }
    });
  }

  Future<void> _saveLot() async {
    if (_isSaving) return;
    final l10n = context.l10n;
    if (!_submittedOnce) {
      setState(() => _submittedOnce = true);
    }

    final valid = FormValidationHelper.validateAndFocusFirstInvalid(
      formKey: _formKey,
      orderedAnchors: [
        ValidatedFieldAnchor(
          fieldKey: _numberFieldKey,
          focusNode: _numberFocus,
        ),
        ValidatedFieldAnchor(fieldKey: _titleFieldKey, focusNode: _titleFocus),
        ValidatedFieldAnchor(fieldKey: _notesFieldKey, focusNode: _notesFocus),
      ],
    );
    if (!valid) return;

    final designDrafts = <LotDesignDraftInput>[];
    if (_useDesigns) {
      for (final d in _designs) {
        final colourDrafts = <LotColourDraftInput>[];
        for (final c in d.colours) {
          final parsedQty = AppValidators.parseQuantityExact(c.qtyCtrl.text);
          if (!parsedQty.validation.isValid ||
              parsedQty.value == null ||
              parsedQty.value! <= 0) {
            setState(
              () => _submitError = context.l10n.lotEnterPositiveQtyForVariant(
                d.designName,
                c.colourName,
              ),
            );
            return;
          }
          final parsedPrice = AppValidators.parseRupeesToPaiseExact(
            c.priceCtrl.text,
            isRequired: false,
            allowZero: true,
          );
          if (!parsedPrice.validation.isValid || parsedPrice.paise == null) {
            setState(
              () => _submitError = context.l10n.lotEnterValidPriceForVariant(
                d.designName,
                c.colourName,
              ),
            );
            return;
          }
          colourDrafts.add(
            LotColourDraftInput(
              colourName: c.colourName,
              colourHex: c.colourHex,
              initialQuantity: parsedQty.value!,
              unitPricePaise: parsedPrice.paise!,
            ),
          );
        }
        designDrafts.add(
          LotDesignDraftInput(
            designName: d.designName,
            notes: d.notes,
            colours: colourDrafts,
          ),
        );
      }
    } else if (_colourOnlyVariants.isNotEmpty) {
      final colourDrafts = <LotColourDraftInput>[];
      for (final c in _colourOnlyVariants) {
        final parsedQty = AppValidators.parseQuantityExact(c.qtyCtrl.text);
        if (!parsedQty.validation.isValid ||
            parsedQty.value == null ||
            parsedQty.value! <= 0) {
          setState(
            () => _submitError = context.l10n.lotEnterPositiveQtyFor(
              c.colourName,
            ),
          );
          return;
        }
        final parsedPrice = AppValidators.parseRupeesToPaiseExact(
          c.priceCtrl.text,
          isRequired: false,
          allowZero: true,
        );
        if (!parsedPrice.validation.isValid || parsedPrice.paise == null) {
          setState(
            () =>
                _submitError = context.l10n.lotEnterValidPriceFor(c.colourName),
          );
          return;
        }
        colourDrafts.add(
          LotColourDraftInput(
            colourName: c.colourName,
            colourHex: c.colourHex,
            initialQuantity: parsedQty.value!,
            unitPricePaise: parsedPrice.paise!,
          ),
        );
      }
      designDrafts.add(
        LotDesignDraftInput(
          designName: kColourOnlyDesignSentinel,
          notes: 'Colour-only lot variants',
          colours: colourDrafts,
        ),
      );
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    try {
      final created = await _lotRepo.createLotComplete(
        lotNumber: _numberCtrl.text,
        title: _titleCtrl.text,
        notes: _notesCtrl.text,
        transactionAtUtcMillis: _txDateUtc,
        designs: designDrafts,
        initialAssignments: _initialAssignments,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        context.l10n.lotCreatedSuccess(created.lotNumber),
      );
      context.pop(true);
    } on DomainValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _submitError = ValidationLocalizer.localizeDomainException(l10n, e);
      });
    } catch (e) {
      if (!mounted) return;
      final duplicate = '$e'.contains('UNIQUE');
      setState(() {
        _isSaving = false;
        _submitError = duplicate
            ? l10n.lotDuplicateError
            : ValidationLocalizer.describeError(l10n, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final availableKnownDesigns = _knownDesignNames
        .where((n) => !_hasDesignName(n))
        .toList();

    return AppUnsavedChangesGuard.tracked(
      tracker: _dirty,
      child: AppScaffold(
        title: l10n.lotCreateAction,
        body: Form(
          key: _formKey,
          autovalidateMode: _submittedOnce
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    AppCard(
                      isGlass: true,
                      blurSigma: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            context.l10n.lotSummaryLive,
                            variant: AppTextVariant.bodySmall,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppSummaryStrip(
                            metrics: [
                              if (_useDesigns)
                                AppSummaryMetric(
                                  label: context.l10n.designsTabLabel,
                                  value: '${_designs.length}',
                                  tone: AppStatusTone.info,
                                ),
                              AppSummaryMetric(
                                label: context.l10n.lotColoursLabel,
                                value: '$_totalColoursCount',
                                tone: AppStatusTone.info,
                              ),
                              AppSummaryMetric(
                                label: context.l10n.lotTotalQtyLabel,
                                value: context.l10n.lotPiecesValue(
                                  MoneyFormatter.formatQuantity(_totalQuantity),
                                ),
                                tone: _totalQuantity > 0
                                    ? AppStatusTone.good
                                    : AppStatusTone.neutral,
                              ),
                              AppSummaryMetric(
                                label: context.l10n.lotSkuValueLabel,
                                value: MoneyFormatter.formatPaise(
                                  _totalValuePaise,
                                ),
                                tone: _totalValuePaise > 0
                                    ? AppStatusTone.good
                                    : AppStatusTone.neutral,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            context.l10n.lotSectionInfo,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _numberFieldKey,
                            controller: _numberCtrl,
                            focusNode: _numberFocus,
                            label: l10n.lotNumberLabel,
                            prefixIcon: AppIcons.tag,
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
                            fieldKey: _titleFieldKey,
                            controller: _titleCtrl,
                            focusNode: _titleFocus,
                            label: l10n.lotTitleLabel,
                            prefixIcon: AppIcons.title,
                            textInputAction: TextInputAction.next,
                            maxLength: ValidationLimits.maxPersonNameLength,
                            validator: ValidationLocalizer.wrap(
                              l10n,
                              (v) => AppValidators.maxLengthValidator(
                                v,
                                maxLength: ValidationLimits.maxPersonNameLength,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDatePicker(
                            label: l10n.lotDateLabel,
                            selectedUtcMillis: _txDateUtc,
                            onDateSelectedUtcMillis: (utc) =>
                                _edit(() => _txDateUtc = utc),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            fieldKey: _notesFieldKey,
                            controller: _notesCtrl,
                            focusNode: _notesFocus,
                            label: l10n.lotNotesLabel,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            context.l10n.lotSectionDesigns,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            context.l10n.lotSectionDesignsHelp,
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppChip(
                                label: context.l10n.lotModeWithDesigns,
                                selected: _useDesigns,
                                onSelected: (selected) {
                                  _dirty.markDirty();
                                  if (selected && !_useDesigns) {
                                    setState(() => _useDesigns = true);
                                  }
                                },
                              ),
                              AppChip(
                                label: context.l10n.lotModeColourOnly,
                                selected: !_useDesigns,
                                onSelected: (selected) {
                                  _dirty.markDirty();
                                  if (selected && _useDesigns) {
                                    setState(() => _useDesigns = false);
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_useDesigns) ...[
                            AppFormRow(
                              spacing: AppSpacing.sm,
                              children: [
                                if (availableKnownDesigns.isNotEmpty)
                                  AppSelect<String>(
                                    key: ValueKey<String>(
                                      'known_designs_${availableKnownDesigns.join('|')}',
                                    ),
                                    label: context.l10n.lotSelectExistingDesign,
                                    value:
                                        availableKnownDesigns.contains(
                                          _selectedKnownDesign,
                                        )
                                        ? _selectedKnownDesign
                                        : null,
                                    items: availableKnownDesigns,
                                    itemLabelBuilder: (name) => name,
                                    onChanged: (val) {
                                      _dirty.markDirty();
                                      if (val != null) {
                                        _addExistingDesign(val);
                                      }
                                    },
                                  ),
                                AppButton(
                                  label: _showInlineDesignForm
                                      ? 'Close'
                                      : context.l10n.lotAddNewDesign,
                                  icon: _showInlineDesignForm
                                      ? AppIcons.close
                                      : AppIcons.add,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: () => setState(() {
                                    _showInlineDesignForm =
                                        !_showInlineDesignForm;
                                    _inlineDesignError = null;
                                  }),
                                ),
                              ],
                            ),
                            if (_showInlineDesignForm) ...[
                              const SizedBox(height: AppSpacing.md),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  color: colorScheme.surfaceContainerLowest
                                      .withValues(alpha: 0.55),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    AppText(
                                      context.l10n.lotNewDesignInline,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(
                                      controller: _newDesignNameCtrl,
                                      label: l10n.designNameLabel,
                                      maxLength:
                                          ValidationLimits.maxShortNameLength,
                                      onChanged: (_) {
                                        _dirty.markDirty();
                                        if (_inlineDesignError != null) {
                                          setState(
                                            () => _inlineDesignError = null,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(
                                      controller: _newDesignPriceCtrl,
                                      validator: ValidationLocalizer.wrap(
                                        context.l10n,
                                        (v) =>
                                            AppValidators.nonNegativeAmountValidator(
                                              v,
                                              isRequired: false,
                                            ),
                                      ),
                                      label:
                                          context.l10n.lotDefaultUnitPriceLabel,
                                      hint: '0.00',
                                      prefixIcon: AppIcons.rupee,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: [
                                        AppInputFormatters.currencyDecimal,
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppTextField(
                                      controller: _newDesignNotesCtrl,
                                      label: l10n.lotNotesLabel,
                                      maxLength:
                                          ValidationLimits.maxNotesLength,
                                    ),
                                    if (_inlineDesignError != null) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      AppText(
                                        _inlineDesignError!,
                                        color: colorScheme.error,
                                        variant: AppTextVariant.bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    AppButton(
                                      label: context.l10n.lotAddDesignToLot,
                                      icon: AppIcons.confirm,
                                      onPressed: _saveInlineNewDesign,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (!_showInlineDesignForm &&
                                _inlineDesignError != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              AppText(
                                _inlineDesignError!,
                                color: colorScheme.error,
                                variant: AppTextVariant.bodySmall,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            if (_designs.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: AppText(
                                  context.l10n.lotNoDesignsYet,
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              for (final design in _designs) ...[
                                LotCreateDesignCard(
                                  key: ValueKey<String>(design.id),
                                  design: design,
                                  onPickColours: () =>
                                      _pickColoursForDesign(design),
                                  onRemoveDesign: () => _removeDesign(design),
                                  onRemoveColour: (c) => setState(() {
                                    design.colours.remove(c);
                                    c.dispose();
                                  }),
                                  onValueChanged: () => _edit(() {}),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                          ] else ...[
                            AppActionRow(
                              content: AppText(
                                context.l10n.lotColourVariantsCount(
                                  _colourOnlyVariants.length,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                              actions: [
                                AppButton(
                                  label: context.l10n.lotAddColours,
                                  icon: AppIcons.colour,
                                  variant: AppButtonVariant.secondary,
                                  onPressed: _pickColoursForColourOnly,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (_colourOnlyVariants.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                  ),
                                ),
                                child: AppText(
                                  context.l10n.lotAddColoursHelp,
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              for (final c in _colourOnlyVariants)
                                LotCreateColourRow(
                                  key: ValueKey<String>(c.id),
                                  colour: c,
                                  onRemove: () => setState(() {
                                    _colourOnlyVariants.remove(c);
                                    c.dispose();
                                  }),
                                  onChanged: () => _edit(() {}),
                                ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppActionRow(
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppHeading(
                                  l10n.prodHistoryInitialAssignmentsTitle,
                                  level: AppHeadingLevel.h3,
                                ),
                                AppText(
                                  l10n.prodHistoryInitialAssignmentsSubtitle,
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            actions: [
                              AppButton(
                                label: l10n.prodHistoryAddAssignmentAction,
                                icon: AppIcons.assignWorker,
                                variant: AppButtonVariant.secondary,
                                onPressed: _totalColoursCount > 0
                                    ? _showAddInitialAssignmentSheet
                                    : null,
                              ),
                            ],
                          ),
                          if (_initialAssignments.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            for (var i = 0; i < _initialAssignments.length; i++)
                              Builder(
                                builder: (context) {
                                  final a = _initialAssignments[i];
                                  final pName =
                                      _activeProcesses
                                          .where((p) => p.id == a.processId)
                                          .firstOrNull
                                          ?.name ??
                                      a.processId;
                                  final wName =
                                      _activeWorkers
                                          .where((w) => w.id == a.workerId)
                                          .firstOrNull
                                          ?.name ??
                                      a.workerId;
                                  return AppListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(AppIcons.processIcon(pName)),
                                    title: Text('$pName • $wName'),
                                    subtitle: Text(
                                      '${formatVariantLabel(a.designName, a.colourName)} • ${a.quantity} pcs @ ${MoneyFormatter.formatPaise(a.agreedRatePaise)}/pc',
                                    ),
                                    trailing: AppIconButton(
                                      icon: AppIcons.close,
                                      tooltip: context.l10n.actionDelete,
                                      onPressed: () => setState(
                                        () => _initialAssignments.removeAt(i),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),

                    if (_submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        borderColor: colorScheme.error,
                        child: AppText(_submitError!, color: colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: AppButton(
                  label: _totalQuantity > 0
                      ? 'Save Lot (${MoneyFormatter.formatQuantity(_totalQuantity)} pcs)'
                      : l10n.actionSave,
                  icon: AppIcons.confirm,
                  isExpanded: true,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _saveLot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
