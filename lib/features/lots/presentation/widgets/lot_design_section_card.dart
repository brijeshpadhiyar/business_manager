import 'dart:typed_data';

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_edit_sheets.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Card displaying one design group and its nested colour variant cards on
/// [LotDetailPage].
final class LotDesignSectionCard extends StatelessWidget {
  const LotDesignSectionCard({
    super.key,
    required this.lotId,
    required this.item,
    required this.balancesByColourId,
    required this.operationsByColourId,
  });

  final String lotId;
  final DesignWithColours item;
  final Map<String, DesignColourStockBalance> balancesByColourId;
  final Map<String, List<JobProcessEntity>> operationsByColourId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isColourOnly = item.design.designName == kColourOnlyDesignSentinel;
    final designLabel = isColourOnly
        ? 'Colours (No Design)'
        : item.design.designName;

    return AppCard.listItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      designLabel,
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(
                      'Total: ${item.colours.fold<int>(0, (s, c) => s + c.initialQuantity)} pcs • ${item.colours.length} colour${item.colours.length == 1 ? '' : 's'}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!isColourOnly)
                AppIconButton(
                  icon: AppIcons.edit,
                  tooltip: l10n.designEditAction,
                  onPressed: () => LotEditSheets.showDesignSheet(
                    context,
                    lotId: lotId,
                    existing: item.design,
                  ),
                ),
              AppIconButton(
                icon: AppIcons.delete,
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
              icon: AppIcons.colour,
              variant: AppButtonVariant.secondary,
              onPressed: () => LotEditSheets.showVisualColourPicker(
                context,
                lotId: lotId,
                lotDesignId: isColourOnly ? null : item.design.id,
                designDisplayName: isColourOnly ? null : item.design.designName,
                existingColourNames: item.colours
                    .map((c) => c.colourName)
                    .toSet(),
              ),
            ),
          ),
          if (item.colours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 680
                    ? 3
                    : (constraints.maxWidth >= 340 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (cols - 1))) /
                    cols;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in item.colours)
                      SizedBox(
                        width: cardWidth,
                        child: _PremiumLotColourCard(
                          key: ValueKey<String>(c.id),
                          colour: c,
                          designName: isColourOnly
                              ? null
                              : item.design.designName,
                          balance: balancesByColourId[c.id],
                          operations:
                              operationsByColourId[c.id] ??
                              const <JobProcessEntity>[],
                          onTap: () async {
                            await context.push(
                              RoutePaths.lotColourDetail(lotId, c.id),
                            );
                            if (context.mounted) {
                              await context.read<LotDetailCubit>().loadLot(
                                lotId,
                              );
                            }
                          },
                          onEdit: () => LotEditSheets.showColourSheet(
                            context,
                            lotId: lotId,
                            lotDesignId: item.design.id,
                            existing: c,
                          ),
                          onDelete: () async {
                            final ok = await AppDialog.showConfirmation(
                              context,
                              title: l10n.colourDeleteConfirmTitle,
                              message: l10n.colourDeleteConfirmMessage,
                              confirmLabel: l10n.actionDelete,
                              cancelLabel: l10n.actionCancel,
                              isDestructive: true,
                            );
                            if (ok == true && context.mounted) {
                              await context.read<LotDetailCubit>().deleteColour(
                                lotId,
                                c.id,
                              );
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// StitchFlow V1.3 — Premium Clickable Lot Colour Card with large actual
/// colour preview banner, HEX code, design label, quantities, current stage,
/// and current stock location.
final class _PremiumLotColourCard extends StatelessWidget {
  const _PremiumLotColourCard({
    super.key,
    required this.colour,
    this.designName,
    this.balance,
    required this.operations,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DesignColourEntity colour;
  final String? designName;
  final DesignColourStockBalance? balance;
  final List<JobProcessEntity> operations;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _resolveCurrentStage() {
    if (operations.isEmpty) return 'Not Started';
    final active = operations.where((op) => !op.status.isTerminal).toList();
    if (active.isNotEmpty) {
      return active.last.processName;
    }
    return '${operations.last.processName} (Done)';
  }

  String _resolveStockLocation() {
    final inHouse = balance?.physicalAvailableInHouse ?? colour.initialQuantity;
    final withWorkers = balance?.totalPendingWithWorkers ?? 0;
    if (withWorkers == 0) {
      return 'Factory ($inHouse pcs)';
    }
    final activeHolders = operations
        .where((op) => op.pendingQuantity > 0 && op.workerName != null)
        .map((op) => op.workerName!)
        .toSet()
        .toList();
    if (inHouse == 0 && activeHolders.length == 1) {
      return '${activeHolders.first} ($withWorkers pcs)';
    }
    return 'Factory $inHouse • Workers $withWorkers';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final swatch = AppColourUtils.resolveColor(
      colour.colourHex,
      fallbackName: colour.colourName,
    );
    final hexLabel =
        AppColourUtils.normalizeHex(colour.colourHex) ??
        AppColourUtils.toHex(swatch);
    final onSwatch = AppColourUtils.contrastForeground(swatch);
    final borderColor = AppColourUtils.swatchBorderColor(swatch, brightness);

    final totalQty = colour.initialQuantity;
    final pendingQty = balance?.totalPendingWithWorkers ?? 0;
    final completedQty = operations.fold<int>(
      0,
      (sum, op) =>
          sum + op.returnedToFactoryQuantity + op.transferredOutQuantity,
    );
    final stageLabel = _resolveCurrentStage();
    final locationLabel = _resolveStockLocation();

    return AppCard.listItem(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lgBorder,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xsm,
            ),
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xsm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: onSwatch.withValues(alpha: 0.14),
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(
                            color: onSwatch.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          hexLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: onSwatch,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    AppIconButton(
                      onPressed: onEdit,
                      tooltip: context.l10n.colourEditAction,
                      compact: true,
                      color: onSwatch,
                      icon: AppIcons.edit,
                    ),
                    AppIconButton(
                      onPressed: onDelete,
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      compact: true,
                      color: onSwatch,
                      icon: AppIcons.delete,
                    ),
                  ],
                ),
                Text(
                  colour.colourName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: onSwatch, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (designName != null && designName!.isNotEmpty) ...[
                  AppText(
                    context.l10n.lotDesignValue(designName!),
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    _MiniMetric(
                      label: context.l10n.lotTotalLabel,
                      value: '$totalQty',
                    ),
                    _MiniMetric(
                      label: context.l10n.lotDoneLabel,
                      value: '$completedQty',
                    ),
                    _MiniMetric(
                      label: context.l10n.statusPending,
                      value: '$pendingQty',
                      highlight: pendingQty > 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xsm),
                Row(
                  children: [
                    Icon(
                      AppIcons.processIcon(stageLabel),
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        stageLabel,
                        variant: AppTextVariant.bodySmall,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      AppIcons.location,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        locationLabel,
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          color: colorScheme.onSurfaceVariant,
        ),
        AppText(
          value,
          variant: AppTextVariant.numeric,
          fontWeight: FontWeight.w700,
          color: highlight ? colorScheme.tertiary : colorScheme.onSurface,
        ),
      ],
    );
  }
}

/// Asynchronous thumbnail + zoom dialog for a lot photo on [LotDetailPage].
final class LotPhotoTile extends StatefulWidget {
  const LotPhotoTile({super.key, required this.photo, required this.onRemove});

  final LotAttachmentEntity photo;
  final VoidCallback onRemove;

  @override
  State<LotPhotoTile> createState() => _LotPhotoTileState();
}

final class _LotPhotoTileState extends State<LotPhotoTile> {
  late Future<Uint8List?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = context.read<LotDetailCubit>().readPhotoBytes(
      widget.photo.relativePath,
    );
  }

  @override
  void didUpdateWidget(covariant LotPhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.relativePath != widget.photo.relativePath) {
      _photoFuture = context.read<LotDetailCubit>().readPhotoBytes(
        widget.photo.relativePath,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final thumbCachePx = (112 * dpr).round().clamp(112, 448);

    return FutureBuilder<Uint8List?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        Widget preview;
        if (snapshot.connectionState == ConnectionState.waiting) {
          preview = const AppLoader.inline(size: 20);
        } else if (snapshot.data == null) {
          preview = Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.imageError),
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
            onTap: () => AppDialog.showCustom<void>(
              context,
              builder: (dlgCtx) => AppDialog(
                title: l10n.lotPhotosHeading,
                cancelLabel: l10n.actionClose,
                content: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: AppRadius.mdBorder,
                    child: Image(
                      image: ResizeImage(
                        MemoryImage(bytes),
                        width:
                            (MediaQuery.sizeOf(dlgCtx).width *
                                    MediaQuery.devicePixelRatioOf(dlgCtx) *
                                    2)
                                .round(),
                        policy: ResizeImagePolicy.fit,
                      ),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              cacheWidth: thumbCachePx,
              gaplessPlayback: true,
            ),
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
                child: AppIconButton(
                  isFilled: true,
                  compact: true,
                  tooltip: l10n.actionDelete,
                  icon: AppIcons.close,
                  onPressed: widget.onRemove,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
