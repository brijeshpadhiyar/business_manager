import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_design_section_card.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_edit_sheets.dart';
import 'package:business_manager/features/parties/presentation/widgets/lot_pnl_section.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
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
    final XFile? picked;
    try {
      picked = await getIt<AppLockCubit>().runWithSystemPicker(
        () => picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        ),
      );
    } catch (_) {
      return;
    }
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
      AppFeedback.showError(
        context,
        ValidationLocalizer.localizeDomainCode(
          context.l10n,
          err,
          fallback: context.l10n.errorUnexpected,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocSelector<
      LotDetailCubit,
      LotDetailState,
      ({LotDetailStatus status, LotDetailAggregate? detail, String? error})
    >(
      selector: (s) =>
          (status: s.status, detail: s.detail, error: s.errorMessage),
      builder: (context, slice) {
        final detail = slice.detail;
        return AppScaffold(
          title: detail?.lot.lotNumber ?? l10n.lotsHeading,
          actions: detail == null
              ? null
              : [
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: l10n.lotEditAction,
                    onPressed: () =>
                        LotEditSheets.showEditLotSheet(context, detail.lot),
                  ),
                  AppIconButton(
                    icon: AppIcons.archive,
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
          body: switch (slice.status) {
            LotDetailStatus.initial ||
            LotDetailStatus.loading => const AppLoader(),
            LotDetailStatus.error => AppErrorView(
              title: l10n.errorUnexpected,
              message: slice.error,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<LotDetailCubit>().loadLot(lotId),
            ),
            LotDetailStatus.loaded => _buildLoaded(context, detail!),
          },
        );
      },
    );
  }

  Widget _buildLoaded(BuildContext context, LotDetailAggregate detail) {
    final l10n = context.l10n;
    final totalInitialPieces = detail.designs.fold<int>(
      0,
      (s, d) => s + d.colours.fold<int>(0, (cs, c) => cs + c.initialQuantity),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppActionRow(
                        content: AppText(
                          detail.lot.lotNumber,
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        actions: [
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
                        AppText(
                          detail.lot.notes!,
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: context.l10n.lotRoutingHandovers,
                        icon: AppIcons.routeTransfer,
                        isExpanded: true,
                        onPressed: () =>
                            context.push(RoutePaths.lotRouting(lotId)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: l10n.prodHistoryViewLotHistory,
                              icon: AppIcons.productionHistory,
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  context.push(RoutePaths.lotHistory(lotId)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: l10n.prodHistoryViewTimeline,
                              icon: AppIcons.timeline,
                              variant: AppButtonVariant.outlined,
                              onPressed: () =>
                                  context.push(RoutePaths.lotTimeline(lotId)),
                            ),
                          ),
                        ],
                      ),
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
                    if (supportsCameraCapture)
                      AppButton(
                        label: l10n.lotAddPhotoCamera,
                        icon: AppIcons.camera,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            _pickAndSavePhoto(context, ImageSource.camera),
                      ),
                    AppButton(
                      label: l10n.lotAddPhotoGallery,
                      icon: AppIcons.gallery,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          _pickAndSavePhoto(context, ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (detail.photos.isEmpty)
                  AppCard.listItem(
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
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (ctx, i) {
                        final photo = detail.photos[i];
                        return LotPhotoTile(
                          key: ValueKey<String>(photo.id),
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
                  '${l10n.designsHeading} ($totalInitialPieces pcs)',
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: context.l10n.lotAddColourNoDesign,
                      icon: AppIcons.colour,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        final colourOnlyGroup = detail.designs
                            .where(
                              (d) =>
                                  d.design.designName ==
                                  kColourOnlyDesignSentinel,
                            )
                            .firstOrNull;
                        final existingNames = colourOnlyGroup == null
                            ? const <String>{}
                            : colourOnlyGroup.colours
                                  .map((c) => c.colourName)
                                  .toSet();
                        LotEditSheets.showVisualColourPicker(
                          context,
                          lotId: lotId,
                          existingColourNames: existingNames,
                        );
                      },
                    ),
                    GuideTarget(
                      id: GuideTargetId.lotDetailAddDesign,
                      child: AppButton(
                        label: l10n.designAddAction,
                        icon: AppIcons.add,
                        onPressed: () => LotEditSheets.showDesignSheet(
                          context,
                          lotId: lotId,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (detail.designs.isNotEmpty) ...[
                  AppSearchField(
                    label: l10n.designsSearchHint,
                    debounceDuration: const Duration(milliseconds: 120),
                    onChanged: context.read<LotDetailCubit>().setDesignSearch,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
        BlocSelector<
          LotDetailCubit,
          LotDetailState,
          ({
            String query,
            Map<String, DesignColourStockBalance> balancesByColourId,
            Map<String, List<JobProcessEntity>> operationsByColourId,
          })
        >(
          selector: (s) => (
            query: s.designSearchQuery,
            balancesByColourId: s.balancesByColourId,
            operationsByColourId: s.operationsByColourId,
          ),
          builder: (context, slice) {
            final query = slice.query.trim().toLowerCase();
            final filteredDesigns = query.isEmpty
                ? detail.designs
                : detail.designs
                      .where(
                        (d) =>
                            d.design.designName.toLowerCase().contains(query) ||
                            d.colours.any(
                              (c) => c.colourName.toLowerCase().contains(query),
                            ),
                      )
                      .toList(growable: false);

            if (filteredDesigns.isEmpty) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: AppIcons.designs,
                    title: l10n.designsEmptyTitle,
                    subtitle: l10n.designsEmptySubtitle,
                    actionLabel: l10n.designAddAction,
                    onAction: () => LotEditSheets.showDesignSheet(
                      context,
                      lotId: lotId,
                    ),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverList.separated(
                itemCount: filteredDesigns.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (ctx, i) {
                  final item = filteredDesigns[i];
                  return LotDesignSectionCard(
                    key: ValueKey<String>(item.design.id),
                    lotId: lotId,
                    item: item,
                    balancesByColourId: slice.balancesByColourId,
                    operationsByColourId: slice.operationsByColourId,
                  );
                },
              ),
            );
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: LotPnlSection(lotId: lotId),
          ),
        ),
      ],
    );
  }
}
