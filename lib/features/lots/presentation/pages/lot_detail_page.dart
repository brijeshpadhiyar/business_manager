import 'dart:typed_data';

import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

final class LotDetailPage extends StatelessWidget {
  const LotDetailPage({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotDetailCubit>(
      create: (_) => getIt<LotDetailCubit>()..loadLot(lotId),
      child: _LotDetailView(lotId: lotId),
    );
  }
}

final class _LotDetailView extends StatelessWidget {
  const _LotDetailView({required this.lotId});

  final String lotId;

  Future<void> _pickAndSavePhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    final cubit = context.read<LotDetailCubit>();
    final picker = ImagePicker();
    final picked = await getIt<AppLockCubit>().runWithSystemPicker(
      () => picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      ),
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final err = await cubit.addPhoto(
      lotId: lotId,
      bytes: bytes,
      fileExtension: ext,
      mimeType: picked.mimeType ?? 'image/jpeg',
    );
    if (err != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _showEditLotSheet(BuildContext context, LotEntity lot) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final numberCtrl = TextEditingController(text: lot.lotNumber);
    final titleCtrl = TextEditingController(text: lot.title ?? '');
    final notesCtrl = TextEditingController(text: lot.notes ?? '');
    var status = lot.status;
    var txDateUtc = lot.transactionAt;
    String? submitError;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.lotEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: numberCtrl,
                    label: l10n.lotNumberLabel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: titleCtrl,
                    label: l10n.lotTitleLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<LotStatus>(
                    label: l10n.lotStatusLabel,
                    value: status,
                    items: const [LotStatus.active, LotStatus.completed],
                    itemLabelBuilder: (s) => s == LotStatus.active
                        ? l10n.lotsStatusActive
                        : l10n.lotsStatusCompleted,
                    onChanged: (v) {
                      if (v != null) setSheetState(() => status = v);
                    },
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
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
                    maxLines: 2,
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
                    isExpanded: true,
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final err = await cubit.updateLot(
                        lotId: lot.id,
                        lotNumber: numberCtrl.text,
                        title: titleCtrl.text,
                        notes: notesCtrl.text,
                        status: status,
                        transactionAtUtcMillis: txDateUtc,
                      );
                      if (err != null) {
                        setSheetState(() {
                          submitError = err.contains('UNIQUE')
                              ? l10n.lotDuplicateError
                              : err;
                        });
                      } else if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      numberCtrl.dispose();
      titleCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _showDesignSheet(
    BuildContext context, {
    LotDesignEntity? existing,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.designName ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String? submitError;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: existing == null ? l10n.designAddAction : l10n.designEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    label: l10n.designNameLabel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
                    maxLines: 2,
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
                    isExpanded: true,
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final err = existing == null
                          ? await cubit.addDesign(
                              lotId: lotId,
                              designName: nameCtrl.text,
                              notes: notesCtrl.text,
                            )
                          : await cubit.editDesign(
                              lotId: lotId,
                              designId: existing.id,
                              designName: nameCtrl.text,
                              notes: notesCtrl.text,
                            );
                      if (err != null) {
                        setSheetState(() {
                          submitError = err.contains('UNIQUE')
                              ? l10n.designDuplicateError
                              : err;
                        });
                      } else if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _showColourSheet(
    BuildContext context, {
    required String lotDesignId,
    DesignColourEntity? existing,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.colourName ?? '');
    final qtyCtrl = TextEditingController(
      text: existing != null ? '${existing.initialQuantity}' : '',
    );
    final priceCtrl = TextEditingController(
      text: existing != null
          ? (existing.unitPricePaise / 100).toStringAsFixed(2)
          : '0',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String? submitError;

    int? parsePaise(String raw) {
      final clean = raw.trim();
      if (clean.isEmpty) return 0;
      final parsed = double.tryParse(clean);
      if (parsed == null || parsed < 0) return null;
      return (parsed * 100).round();
    }

    try {
      await AppBottomSheet.show<void>(
        context,
        title: existing == null ? l10n.colourAddAction : l10n.colourEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    label: l10n.colourNameLabel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: qtyCtrl,
                    label: l10n.colourInitialQtyLabel,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final qty = int.tryParse(v?.trim() ?? '');
                      return (qty == null || qty <= 0)
                          ? l10n.validationPositiveInt
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: priceCtrl,
                    label: l10n.colourUnitPriceLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) => parsePaise(v ?? '') == null
                        ? l10n.validationValidPrice
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
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
                    isExpanded: true,
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final qty = int.parse(qtyCtrl.text.trim());
                      final paise = parsePaise(priceCtrl.text)!;
                      final err = existing == null
                          ? await cubit.addColour(
                              lotId: lotId,
                              lotDesignId: lotDesignId,
                              colourName: nameCtrl.text,
                              initialQuantity: qty,
                              unitPricePaise: paise,
                              notes: notesCtrl.text,
                            )
                          : await cubit.editColour(
                              lotId: lotId,
                              designColourId: existing.id,
                              colourName: nameCtrl.text,
                              initialQuantity: qty,
                              unitPricePaise: paise,
                              notes: notesCtrl.text,
                            );
                      if (err != null) {
                        setSheetState(() {
                          submitError = err.contains('UNIQUE')
                              ? l10n.colourDuplicateError
                              : err;
                        });
                      } else if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      priceCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<LotDetailCubit, LotDetailState>(
      builder: (context, state) {
        final detail = state.detail;
        return AppScaffold(
          title: detail?.lot.lotNumber ?? l10n.lotsHeading,
          actions: detail == null
              ? null
              : [
                  AppIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: l10n.lotEditAction,
                    onPressed: () => _showEditLotSheet(context, detail.lot),
                  ),
                  AppIconButton(
                    icon: Icons.archive_outlined,
                    tooltip: l10n.lotArchiveAction,
                    onPressed: () async {
                      final confirmed = await AppDialog.showConfirmation(
                        context,
                        title: l10n.lotArchiveConfirmTitle,
                        message: l10n.lotArchiveConfirmMessage,
                        confirmLabel: l10n.lotArchiveAction,
                        cancelLabel: l10n.actionCancel,
                        isDestructive: true,
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<LotDetailCubit>().archiveLot(
                          detail.lot.id,
                        );
                        if (context.mounted) context.pop();
                      }
                    },
                  ),
                ],
          padding: EdgeInsets.zero,
          body: switch (state.status) {
            LotDetailStatus.initial ||
            LotDetailStatus.loading => const AppLoader(),
            LotDetailStatus.error => AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<LotDetailCubit>().loadLot(lotId),
            ),
            LotDetailStatus.loaded => _buildLoaded(context, state, detail!),
          },
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    LotDetailState state,
    LotDetailAggregate detail,
  ) {
    final l10n = context.l10n;
    final query = state.designSearchQuery.trim().toLowerCase();
    final filteredDesigns = detail.designs.where((d) {
      if (query.isEmpty) return true;
      return d.design.designName.toLowerCase().contains(query) ||
          d.colours.any((c) => c.colourName.toLowerCase().contains(query));
    }).toList();

    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    detail.lot.lotNumber,
                    variant: AppTextVariant.bodyLarge,
                    fontWeight: FontWeight.w700,
                  ),
                  AppStatusBadge(
                    label: detail.lot.status == LotStatus.active
                        ? l10n.lotsStatusActive
                        : l10n.lotsStatusCompleted,
                    tone: detail.lot.status == LotStatus.active
                        ? AppStatusTone.good
                        : AppStatusTone.info,
                  ),
                ],
              ),
              if (detail.lot.title != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText(detail.lot.title!),
              ],
              const SizedBox(height: AppSpacing.xs),
              AppText(
                '${l10n.lotDateLabel}: ${IstDateTimeHelper.toIstBusinessDate(detail.lot.transactionAt)}',
                variant: AppTextVariant.bodySmall,
              ),
              if (detail.lot.notes != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText(detail.lot.notes!, variant: AppTextVariant.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppHeading(l10n.lotPhotosHeading, level: AppHeadingLevel.h3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppButton(
              label: l10n.lotAddPhotoCamera,
              icon: Icons.photo_camera_outlined,
              variant: AppButtonVariant.outlined,
              onPressed: () => _pickAndSavePhoto(context, ImageSource.camera),
            ),
            AppButton(
              label: l10n.lotAddPhotoGallery,
              icon: Icons.photo_library_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => _pickAndSavePhoto(context, ImageSource.gallery),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (detail.photos.isEmpty)
          AppCard(
            child: AppText(
              l10n.lotPhotosEmpty,
              variant: AppTextVariant.bodySmall,
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: detail.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (ctx, i) {
                final photo = detail.photos[i];
                return _LotPhotoTile(
                  photo: photo,
                  onRemove: () async {
                    final ok = await AppDialog.showConfirmation(
                      ctx,
                      title: l10n.actionDelete,
                      message: l10n.lotPhotoRemoveConfirm,
                      confirmLabel: l10n.actionDelete,
                      cancelLabel: l10n.actionCancel,
                      isDestructive: true,
                    );
                    if (ok == true && ctx.mounted) {
                      await ctx.read<LotDetailCubit>().removePhoto(
                        lotId,
                        photo.id,
                      );
                    }
                  },
                );
              },
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        AppHeading(
          l10n.designsHeading,
          level: AppHeadingLevel.h3,
          trailing: AppButton(
            label: l10n.designAddAction,
            icon: Icons.add,
            onPressed: () => _showDesignSheet(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (detail.designs.isNotEmpty) ...[
          AppTextField(
            label: l10n.designsSearchHint,
            prefixIcon: Icons.search,
            onChanged: context.read<LotDetailCubit>().setDesignSearch,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (filteredDesigns.isEmpty)
          AppEmptyState(
            icon: Icons.style_outlined,
            title: l10n.designsEmptyTitle,
            subtitle: l10n.designsEmptySubtitle,
            actionLabel: l10n.designAddAction,
            onAction: () => _showDesignSheet(context),
          )
        else
          for (final item in filteredDesigns) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: AppText(
                          item.design.designName,
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AppIconButton(
                        icon: Icons.edit_outlined,
                        tooltip: l10n.designEditAction,
                        onPressed: () =>
                            _showDesignSheet(context, existing: item.design),
                      ),
                      AppIconButton(
                        icon: Icons.delete_outline,
                        tooltip: l10n.actionDelete,
                        onPressed: () async {
                          final ok = await AppDialog.showConfirmation(
                            context,
                            title: l10n.designDeleteConfirmTitle,
                            message: l10n.designDeleteConfirmMessage,
                            confirmLabel: l10n.actionDelete,
                            cancelLabel: l10n.actionCancel,
                            isDestructive: true,
                          );
                          if (ok == true && context.mounted) {
                            await context.read<LotDetailCubit>().deleteDesign(
                              lotId,
                              item.design.id,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppButton(
                      label: l10n.colourAddAction,
                      icon: Icons.palette_outlined,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => _showColourSheet(
                        context,
                        lotDesignId: item.design.id,
                      ),
                    ),
                  ),
                  if (item.colours.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(),
                    for (final c in item.colours)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: AppText(
                          c.colourName,
                          fontWeight: FontWeight.w600,
                        ),
                        subtitle: AppText(
                          '${l10n.colourInitialQtyLabel}: ${c.initialQuantity} ${l10n.piecesUnit}  •  ${MoneyFormatter.formatPaise(c.unitPricePaise)}',
                          variant: AppTextVariant.numeric,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIconButton(
                              icon: Icons.edit_outlined,
                              tooltip: l10n.colourEditAction,
                              onPressed: () => _showColourSheet(
                                context,
                                lotDesignId: item.design.id,
                                existing: c,
                              ),
                            ),
                            AppIconButton(
                              icon: Icons.delete_outline,
                              tooltip: l10n.actionDelete,
                              onPressed: () async {
                                final ok = await AppDialog.showConfirmation(
                                  context,
                                  title: l10n.colourDeleteConfirmTitle,
                                  message: l10n.colourDeleteConfirmMessage,
                                  confirmLabel: l10n.actionDelete,
                                  cancelLabel: l10n.actionCancel,
                                  isDestructive: true,
                                );
                                if (ok == true && context.mounted) {
                                  await context
                                      .read<LotDetailCubit>()
                                      .deleteColour(lotId, c.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
      ],
    );
  }
}

final class _LotPhotoTile extends StatelessWidget {
  const _LotPhotoTile({required this.photo, required this.onRemove});

  final LotAttachmentEntity photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Uint8List?>(
      future: context.read<LotDetailCubit>().readPhotoBytes(photo.relativePath),
      builder: (context, snapshot) {
        Widget preview;
        if (snapshot.connectionState == ConnectionState.waiting) {
          preview = const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.data == null) {
          preview = Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.broken_image_outlined),
                  AppText(
                    l10n.lotPhotoMissing,
                    variant: AppTextVariant.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        } else {
          final bytes = snapshot.data!;
          preview = InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (dlgCtx) => Dialog(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InteractiveViewer(
                      child: Image.memory(bytes, fit: BoxFit.contain),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: AppButton(
                        label: l10n.actionClose,
                        variant: AppButtonVariant.text,
                        onPressed: () => Navigator.of(dlgCtx).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            child: Image.memory(bytes, fit: BoxFit.cover),
          );
        }

        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: preview,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
