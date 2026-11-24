import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class LotListPage extends StatelessWidget {
  const LotListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotListCubit>(
      create: (_) => getIt<LotListCubit>()..loadLots(),
      child: const _LotListView(),
    );
  }
}

final class _LotListView extends StatefulWidget {
  const _LotListView();

  @override
  State<_LotListView> createState() => _LotListViewState();
}

final class _LotListViewState extends State<_LotListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateLotSheet(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<LotListCubit>();
    final formKey = GlobalKey<FormState>();
    final numberFieldKey = GlobalKey<FormFieldState<String>>();
    final titleFieldKey = GlobalKey<FormFieldState<String>>();
    final notesFieldKey = GlobalKey<FormFieldState<String>>();
    final numberCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final numberFocus = FocusNode();
    final titleFocus = FocusNode();
    final notesFocus = FocusNode();
    int txDateUtc = IstDateTimeHelper.nowUtcMillis();
    String? submitError;
    bool isSaving = false;
    bool submittedOnce = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.lotCreateAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Form(
              key: formKey,
              autovalidateMode: submittedOnce
                  ? AutovalidateMode.onUserInteraction
                  : AutovalidateMode.disabled,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      fieldKey: numberFieldKey,
                      controller: numberCtrl,
                      focusNode: numberFocus,
                      label: l10n.lotNumberLabel,
                      prefixIcon: Icons.tag,
                      textInputAction: TextInputAction.next,
                      maxLength: ValidationLimits.maxShortNameLength,
                      onChanged: (_) {
                        if (submitError != null) {
                          setSheetState(() => submitError = null);
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
                      fieldKey: titleFieldKey,
                      controller: titleCtrl,
                      focusNode: titleFocus,
                      label: l10n.lotTitleLabel,
                      prefixIcon: Icons.title,
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
                      selectedUtcMillis: txDateUtc,
                      onDateSelectedUtcMillis: (utc) =>
                          setSheetState(() => txDateUtc = utc),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      fieldKey: notesFieldKey,
                      controller: notesCtrl,
                      focusNode: notesFocus,
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
                    if (submitError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(
                        submitError!,
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.actionSave,
                      icon: Icons.check,
                      isExpanded: true,
                      isLoading: isSaving,
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!submittedOnce) {
                                setSheetState(() => submittedOnce = true);
                              }
                              final valid =
                                  FormValidationHelper.validateAndFocusFirstInvalid(
                                    formKey: formKey,
                                    orderedAnchors: [
                                      ValidatedFieldAnchor(
                                        fieldKey: numberFieldKey,
                                        focusNode: numberFocus,
                                      ),
                                      ValidatedFieldAnchor(
                                        fieldKey: titleFieldKey,
                                        focusNode: titleFocus,
                                      ),
                                      ValidatedFieldAnchor(
                                        fieldKey: notesFieldKey,
                                        focusNode: notesFocus,
                                      ),
                                    ],
                                  );
                              if (!valid) return;
                              setSheetState(() {
                                isSaving = true;
                                submitError = null;
                              });
                              final err = await cubit.createLot(
                                lotNumber: numberCtrl.text,
                                title: titleCtrl.text,
                                notes: notesCtrl.text,
                                transactionAtUtcMillis: txDateUtc,
                              );
                              if (err != null) {
                                if (sheetCtx.mounted) {
                                  setSheetState(() {
                                    isSaving = false;
                                    submitError = err.contains('UNIQUE')
                                        ? l10n.lotDuplicateError
                                        : ValidationLocalizer.localizeDomainCode(
                                            l10n,
                                            err,
                                            fallback: err,
                                          );
                                  });
                                }
                              } else if (sheetCtx.mounted) {
                                Navigator.of(sheetCtx).pop();
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      numberCtrl.dispose();
      titleCtrl.dispose();
      notesCtrl.dispose();
      numberFocus.dispose();
      titleFocus.dispose();
      notesFocus.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeading(
                    l10n.lotsHeading,
                    level: AppHeadingLevel.h2,
                    trailing: AppButton(
                      label: l10n.lotCreateAction,
                      icon: Icons.add,
                      onPressed: () => _showCreateLotSheet(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.lotsSearchHint,
                    prefixIcon: Icons.search,
                    onChanged: (q) =>
                        context.read<LotListCubit>().loadLots(searchQuery: q),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<LotListCubit, LotListState>(
                    builder: (context, state) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilterChip(
                            label: Text(l10n.lotsFilterAll),
                            selected: state.statusFilter == null,
                            onSelected: (_) => context
                                .read<LotListCubit>()
                                .loadLots(clearStatusFilter: true),
                          ),
                          FilterChip(
                            label: Text(l10n.lotsStatusActive),
                            selected: state.statusFilter == LotStatus.active,
                            onSelected: (_) => context
                                .read<LotListCubit>()
                                .loadLots(statusFilter: LotStatus.active),
                          ),
                          FilterChip(
                            label: Text(l10n.lotsStatusCompleted),
                            selected: state.statusFilter == LotStatus.completed,
                            onSelected: (_) => context
                                .read<LotListCubit>()
                                .loadLots(statusFilter: LotStatus.completed),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<LotListCubit, LotListState>(
                builder: (context, state) {
                  final Widget body;
                  final Key stateKey;
                  if (state.status == LotListStatus.loading ||
                      state.status == LotListStatus.initial) {
                    stateKey = const ValueKey<String>('loading');
                    body = const AppLoader();
                  } else if (state.status == LotListStatus.error) {
                    stateKey = const ValueKey<String>('error');
                    body = AppErrorView(
                      title: l10n.errorUnexpected,
                      message: state.errorMessage,
                      retryLabel: l10n.actionRetry,
                      onRetry: () => context.read<LotListCubit>().loadLots(),
                    );
                  } else if (state.lots.isEmpty) {
                    stateKey = const ValueKey<String>('empty');
                    body = AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.lotsEmptyTitle,
                      subtitle: l10n.lotsEmptySubtitle,
                      actionLabel: l10n.lotCreateAction,
                      onAction: () => _showCreateLotSheet(context),
                    );
                  } else {
                    stateKey = ValueKey<String>('list_${state.lots.length}');
                    body = ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      itemCount: state.lots.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final lot = state.lots[index];
                        return AppMotionEntrance(
                          index: index,
                          child: AppCard(
                            onTap: () async {
                              await context.push(RoutePaths.lotDetail(lot.id));
                              if (context.mounted) {
                                await context.read<LotListCubit>().loadLots();
                              }
                            },
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        lot.lotNumber,
                                        variant: AppTextVariant.bodyLarge,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      if (lot.title != null) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        AppText(lot.title!),
                                      ],
                                      const SizedBox(height: AppSpacing.xs),
                                      AppText(
                                        IstDateTimeHelper.toIstBusinessDate(
                                          lot.transactionAt,
                                        ),
                                        variant: AppTextVariant.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                AppStatusBadge(
                                  label: switch (lot.status) {
                                    LotStatus.active => l10n.lotsStatusActive,
                                    LotStatus.completed =>
                                      l10n.lotsStatusCompleted,
                                    LotStatus.archived =>
                                      l10n.lotsStatusArchived,
                                  },
                                  tone: switch (lot.status) {
                                    LotStatus.active => AppStatusTone.good,
                                    LotStatus.completed => AppStatusTone.info,
                                    LotStatus.archived => AppStatusTone.neutral,
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return AppStateTransition(stateKey: stateKey, child: body);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
