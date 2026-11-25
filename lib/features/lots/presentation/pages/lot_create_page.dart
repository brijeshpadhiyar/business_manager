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
import 'package:business_manager/features/lots/presentation/widgets/visual_colour_picker_sheet.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Complete one-screen Lot Creation workflow:
/// - Section A: Lot Information (Number, Title, Date, Notes)
/// - Section B: Design Selection (With Designs or Colour-Only) with searchable
///   previously used designs + inline `+ Add New Design` (no navigation away)
/// - Section C: Multi-Colour Variants with per-colour Quantity & SKU Unit Price
///   (pre-filled from design default price and independently overridable)
/// - Live Summary Strip: Total Designs, Total Colours, Total Quantity, Total
///   Estimated SKU Value (in Indian Rupees via `MoneyFormatter`)
/// - Atomic transactional save via [LotRepository.createLotComplete]
final class LotCreatePage extends StatefulWidget {
  const LotCreatePage({super.key});

  @override
  State<LotCreatePage> createState() => _LotCreatePageState();
}

final class _ColourVariantRowState {
  _ColourVariantRowState({
    required this.id,
    required this.colourName,
    this.colourHex,
    required int initialQuantity,
    required int unitPricePaise,
  }) : qtyCtrl = TextEditingController(text: '$initialQuantity'),
       priceCtrl = TextEditingController(
         text: unitPricePaise > 0
             ? MoneyFormatter.formatPaiseForInput(unitPricePaise)
             : '',
       );

  final String id;
  final String colourName;
  final String? colourHex;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  int get quantity => int.tryParse(qtyCtrl.text.trim()) ?? 0;

  int get unitPricePaise {
    final parsed = AppValidators.parseRupeesToPaiseExact(
      priceCtrl.text,
      isRequired: false,
      allowZero: true,
    );
    return parsed.paise ?? 0;
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

final class _DesignBlockState {
  _DesignBlockState({
    required this.id,
    required this.designName,
    this.notes,
    this.defaultUnitPricePaise = 0,
  });

  final String id;
  final String designName;
  final String? notes;
  final int defaultUnitPricePaise;
  final List<_ColourVariantRowState> colours = [];

  int get totalQty => colours.fold(0, (acc, c) => acc + c.quantity);

  int get totalValuePaise =>
      colours.fold(0, (acc, c) => acc + (c.quantity * c.unitPricePaise));

  void dispose() {
    for (final c in colours) {
      c.dispose();
    }
  }
}

final class _LotCreatePageState extends State<LotCreatePage> {
  final _dirty = AppFormDirtyTracker();

  /// setState for a user edit: also marks the form as unsaved.
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

  // Inline "+ Add New Design" controls
  bool _showInlineDesignForm = false;
  final _newDesignNameCtrl = TextEditingController();
  final _newDesignNotesCtrl = TextEditingController();
  final _newDesignPriceCtrl = TextEditingController();
  String? _inlineDesignError;

  // Existing design selector
  List<String> _knownDesignNames = const [];
  String? _selectedKnownDesign;

  // Mode: true = With Designs, false = Colour-Only (No Design)
  bool _useDesigns = true;
  int _txDateUtc = IstDateTimeHelper.nowUtcMillis();

  final List<_DesignBlockState> _designs = [];
  final List<_ColourVariantRowState> _colourOnlyVariants = [];

  // Optional Phase 5 Initial Process Assignments
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
    } catch (_) {
      // Non-blocking suggestion load
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
    if (skuOptions.isEmpty ||
        _activeProcesses.isEmpty ||
        _activeWorkers.isEmpty) {
      AppFeedback.showError(
        context,
        'Add at least one colour variant, active process, and active worker first.',
      );
      return;
    }

    var selectedSkuIdx = 0;
    var selectedProcId = _activeProcesses.first.id;
    var selectedWorkerId = _activeWorkers.first.id;
    final qtyCtrl = TextEditingController(text: '${skuOptions.first.qty}');
    final rateCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(
        _activeProcesses.first.defaultRatePaise,
      ),
    );
    final notesCtrl = TextEditingController();
    String? err;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: context.l10n.prodHistoryAddAssignmentAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppDropdown<int>(
                  label: 'Design / Colour Variant',
                  value: selectedSkuIdx,
                  items: List<int>.generate(skuOptions.length, (i) => i),
                  itemLabelBuilder: (i) {
                    final s = skuOptions[i];
                    return '${formatVariantLabel(s.designName, s.colourName)} (${s.qty} pcs)';
                  },
                  onChanged: (v) {
                    if (v != null) {
                      setSheetState(() {
                        selectedSkuIdx = v;
                        qtyCtrl.text = '${skuOptions[v].qty}';
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdown<String>(
                  label: context.l10n.navProcesses,
                  value: selectedProcId,
                  items: _activeProcesses.map((p) => p.id).toList(),
                  itemLabelBuilder: (id) =>
                      _activeProcesses.firstWhere((p) => p.id == id).name,
                  onChanged: (v) {
                    if (v != null) {
                      final proc = _activeProcesses.firstWhere(
                        (p) => p.id == v,
                      );
                      setSheetState(() {
                        selectedProcId = v;
                        rateCtrl.text = MoneyFormatter.formatPaiseForInput(
                          proc.defaultRatePaise,
                        );
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                AppDropdown<String>(
                  label: context.l10n.navWorkers,
                  value: selectedWorkerId,
                  items: _activeWorkers.map((w) => w.id).toList(),
                  itemLabelBuilder: (id) =>
                      _activeWorkers.firstWhere((w) => w.id == id).name,
                  onChanged: (v) {
                    if (v != null) setSheetState(() => selectedWorkerId = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: qtyCtrl,
                        validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v)),
                        label: 'Qty (pcs)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppTextField(
                        controller: rateCtrl,
                        validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v)),
                        label: 'Locked Rate (₹/pc)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [AppInputFormatters.currencyDecimal],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: notesCtrl,
                  label: context.l10n.stockNotesLabel,
                ),
                if (err != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(err!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: context.l10n.prodHistoryAddAssignmentAction,
                  icon: AppIcons.assignWorker,
                  isExpanded: true,
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                    final parsedRate = AppValidators.parseRupeesToPaiseExact(
                      rateCtrl.text,
                      isRequired: false,
                      allowZero: true,
                    );
                    if (qty <= 0) {
                      setSheetState(() => err = 'Enter a positive quantity.');
                      return;
                    }
                    if (!parsedRate.validation.isValid ||
                        parsedRate.paise == null) {
                      setSheetState(() => err = 'Enter a valid rate.');
                      return;
                    }
                    final sku = skuOptions[selectedSkuIdx];
                    setState(() {
                      _initialAssignments.add(
                        InitialLotProcessAssignmentInput(
                          designName: sku.designName,
                          colourName: sku.colourName,
                          processId: selectedProcId,
                          workerId: selectedWorkerId,
                          quantity: qty,
                          agreedRatePaise: parsedRate.paise!,
                          notes: notesCtrl.text,
                        ),
                      );
                    });
                    Navigator.of(sheetCtx).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      qtyCtrl.dispose();
      rateCtrl.dispose();
      notesCtrl.dispose();
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
        _inlineDesignError = 'Design "$trimmed" is already added to this lot.';
      });
      return;
    }
    setState(() {
      _inlineDesignError = null;
      _submitError = null;
      _designs.add(
        _DesignBlockState(id: 'design_${++_seq}', designName: trimmed),
      );
      _selectedKnownDesign = null;
    });
  }

  void _saveInlineNewDesign() {
    final cleanName = _newDesignNameCtrl.text.trim();
    if (cleanName.isEmpty) {
      setState(() => _inlineDesignError = 'Enter a design name.');
      return;
    }
    if (cleanName.length > ValidationLimits.maxShortNameLength) {
      setState(() => _inlineDesignError = 'Design name is too long.');
      return;
    }
    if (_hasDesignName(cleanName)) {
      setState(
        () => _inlineDesignError =
            'Design "$cleanName" is already added to this lot.',
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
        () => _inlineDesignError = 'Enter a valid non-negative default price.',
      );
      return;
    }
    final notes = _newDesignNotesCtrl.text.trim();
    setState(() {
      _designs.add(
        _DesignBlockState(
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

  void _removeDesign(_DesignBlockState design) {
    _dirty.markDirty();
    setState(() {
      _designs.remove(design);
      design.dispose();
    });
  }

  Future<void> _pickColoursForDesign(_DesignBlockState design) async {
    _dirty.markDirty();
    final existingLower = design.colours
        .map((c) => c.colourName.trim().toLowerCase())
        .toSet();
    final picked = await VisualColourPickerSheet.show(
      context,
      title: 'Select Colours — ${design.designName}',
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
          _ColourVariantRowState(
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
      title: 'Select Colours (Colour-Only Lot)',
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
          _ColourVariantRowState(
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

    // Validate all colour quantities & prices cleanly before calling repository.
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
              () => _submitError =
                  'Enter a positive quantity for ${d.designName} — ${c.colourName}.',
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
              () => _submitError =
                  'Enter a valid non-negative unit price for ${d.designName} — ${c.colourName}.',
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
            () =>
                _submitError = 'Enter a positive quantity for ${c.colourName}.',
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
            () => _submitError =
                'Enter a valid non-negative unit price for ${c.colourName}.',
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
        'Lot ${created.lotNumber} created successfully.',
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
      final raw = e.toString();
      setState(() {
        _isSaving = false;
        _submitError = raw.contains('UNIQUE') ? l10n.lotDuplicateError : raw;
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
                    // Live Summary Header (full glass hero)
                    AppCard(
                      isGlass: true,
                      blurSigma: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(
                            'Lot Summary (Live)',
                            variant: AppTextVariant.bodySmall,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppSummaryStrip(
                            metrics: [
                              if (_useDesigns)
                                AppSummaryMetric(
                                  label: 'Designs',
                                  value: '${_designs.length}',
                                  tone: AppStatusTone.info,
                                ),
                              AppSummaryMetric(
                                label: 'Colours',
                                value: '$_totalColoursCount',
                                tone: AppStatusTone.info,
                              ),
                              AppSummaryMetric(
                                label: 'Total Qty',
                                value:
                                    '${MoneyFormatter.formatQuantity(_totalQuantity)} pcs',
                                tone: _totalQuantity > 0
                                    ? AppStatusTone.good
                                    : AppStatusTone.neutral,
                              ),
                              AppSummaryMetric(
                                label: 'SKU Value',
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

                    // Section A: Lot Information
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppHeading(
                            '1. Lot Information',
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

                    // Section B & C: Designs, Colours & Direct SKU Pricing
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AppHeading(
                            '2. Designs, Colours & SKU Pricing',
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            'Unit prices here are SKU reference prices (separate from worker labour rates). You can add designs, colours, quantities, and prices in one workflow.',
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              ChoiceChip(
                                label: const Text('With Design(s)'),
                                selected: _useDesigns,
                                onSelected: (selected) {
                                  _dirty.markDirty();
                                  if (selected && !_useDesigns) {
                                    setState(() => _useDesigns = true);
                                  }
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Colour-Only (No Design)'),
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
                            // Side by side when there is room, stacked on phones.
                            AppFormRow(
                              spacing: AppSpacing.sm,
                              children: [
                                if (availableKnownDesigns.isNotEmpty)
                                  AppDropdown<String>(
                                    key: ValueKey<String>(
                                      'known_designs_${availableKnownDesigns.join('|')}',
                                    ),
                                    label: 'Select Existing Design',
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
                                      : 'Add New Design',
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
                                    const AppText(
                                      'New Design (Inline)',
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
                                      validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v, isRequired: false)),
                                      label: 'Default Unit Price (₹ / pc, optional)',
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
                                      label: 'Add Design to Lot',
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
                                  'No designs added yet. Select an existing design or tap "+ Add New Design" above (or save an empty lot and add designs later).',
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              for (final design in _designs) ...[
                                _buildDesignCard(context, design),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                          ] else ...[
                            AppActionRow(
                              content: AppText(
                                'Colour Variants (${_colourOnlyVariants.length})',
                                fontWeight: FontWeight.w700,
                              ),
                              actions: [
                                AppButton(
                                  label: 'Add Colours',
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
                                  'Tap "Add Colours" to pick colours from the palette or create custom colours with quantity & price.',
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            else
                              for (final c in _colourOnlyVariants)
                                _buildColourRow(
                                  context,
                                  c,
                                  onRemove: () => setState(() {
                                    _colourOnlyVariants.remove(c);
                                    c.dispose();
                                  }),
                                ),
                          ],
                        ],
                      ),
                    ),

                    // Section 3: Optional Initial Process Assignments (Phase 5)
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
                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      AppIcons.processIcon(pName),
                                    ),
                                    title: Text('$pName • $wName'),
                                    subtitle: Text(
                                      '${formatVariantLabel(a.designName, a.colourName)} • ${a.quantity} pcs @ ${MoneyFormatter.formatPaise(a.agreedRatePaise)}/pc',
                                    ),
                                    trailing: AppIconButton(
                                      icon: AppIcons.close,
                                      tooltip: 'Remove',
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

  Widget _buildDesignCard(BuildContext context, _DesignBlockState design) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: ValueKey<String>(design.id),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppActionRow(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  design.designName,
                  variant: AppTextVariant.bodyLarge,
                  fontWeight: FontWeight.w700,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppText(
                      '${design.colours.length} colour(s) • ${MoneyFormatter.formatQuantity(design.totalQty)} pcs',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    if (design.defaultUnitPricePaise > 0)
                      AppStatusBadge(
                        label:
                            'Default: ${MoneyFormatter.formatPaise(design.defaultUnitPricePaise)}',
                        tone: AppStatusTone.info,
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              AppButton(
                label: 'Colours',
                icon: AppIcons.colour,
                variant: AppButtonVariant.outlined,
                onPressed: () => _pickColoursForDesign(design),
              ),
              AppIconButton(
                icon: AppIcons.delete,
                tooltip: 'Remove design',
                onPressed: () => _removeDesign(design),
              ),
            ],
          ),
          if (design.colours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final c in design.colours)
              _buildColourRow(
                context,
                c,
                onRemove: () => setState(() {
                  design.colours.remove(c);
                  c.dispose();
                }),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildColourRow(
    BuildContext context,
    _ColourVariantRowState colour, {
    required VoidCallback onRemove,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineTotalPaise = colour.quantity * colour.unitPricePaise;
    return Padding(
      key: ValueKey<String>(colour.id),
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smBorder,
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppColourSwatch(
                  color: AppColourUtils.resolveColor(colour.colourHex),
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    colour.colourName,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lineTotalPaise > 0)
                  AppText(
                    MoneyFormatter.formatPaise(lineTotalPaise),
                    variant: AppTextVariant.numeric,
                    fontWeight: FontWeight.w600,
                  ),
                AppIconButton(
                  icon: AppIcons.close,
                  tooltip: 'Remove colour',
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: colour.qtyCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v)),
                    label: 'Qty (pcs)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _edit(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: colour.priceCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v, isRequired: false)),
                    label: 'Unit Price (₹)',
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [AppInputFormatters.currencyDecimal],
                    onChanged: (_) => _edit(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
