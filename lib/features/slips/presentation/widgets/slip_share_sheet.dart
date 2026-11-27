import 'package:business_manager/core/validation/validation_localizer.dart';

import 'dart:ui' as ui;

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart';
import 'package:business_manager/features/reports/data/services/report_export_platform.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/domain/services/slip_html_builder.dart';
import 'package:business_manager/features/slips/domain/services/slip_text_formatter.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_preview_card.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Unified Karigar Slip sharing sheet supporting:
/// 1. Branded PNG Receipt Image capture (`RepaintBoundary` -> `share_plus` / Save-As)
/// 2. Bilingual WhatsApp/SMS Text Share & Clipboard Copy
/// 3. Printable HTML / Save as PDF via the cross-platform report print bridge
/// 4. On-the-fly EN / GU slip language switcher (independent of UI locale).
final class SlipShareSheet extends StatefulWidget {
  const SlipShareSheet({
    super.key,
    required this.slip,
    required this.initialLocaleCode,
  });

  final WorkerSlipData slip;
  final String initialLocaleCode;

  static Future<void> show(BuildContext context, WorkerSlipData slip) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return AppBottomSheet.show<void>(
      context,
      title: context.l10n.slipShareSheetTitle,
      builder: (_) => SlipShareSheet(slip: slip, initialLocaleCode: localeCode),
    );
  }

  @override
  State<SlipShareSheet> createState() => _SlipShareSheetState();
}

final class _SlipShareSheetState extends State<SlipShareSheet> {
  static const SlipTextFormatter _textFormatter = SlipTextFormatter();
  static const SlipHtmlBuilder _htmlBuilder = SlipHtmlBuilder();

  final GlobalKey _repaintKey = GlobalKey();
  late String _slipLocale;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _slipLocale = widget.initialLocaleCode == 'gu' ? 'gu' : 'en';
  }

  Future<T> _runWithPicker<T>(Future<T> Function() action) async {
    if (getIt.isRegistered<AppLockCubit>()) {
      return getIt<AppLockCubit>().runWithSystemPicker(action);
    }
    return action();
  }

  Future<void> _sharePngImage() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final stamp = IstDateTimeHelper.formatIstFileTimestamp(
        widget.slip.transactionAtUtcMillis,
      );
      final fileName = 'StitchFlow_${widget.slip.type.name}_$stamp.png';
      await deliverExportedBytes(
        fileName: fileName,
        bytes: bytes,
        mimeType: 'image/png',
        runWithPicker: (action) => _runWithPicker<void>(action),
      );
      if (mounted) {
        AppFeedback.showSuccess(context, context.l10n.slipGeneratedSuccess);
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.describeError(context.l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareWhatsAppText() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final text = _textFormatter.format(widget.slip, localeCode: _slipLocale);
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      await _runWithPicker(
        () => SharePlus.instance.share(
          ShareParams(
            text: text,
            subject: _textFormatter.titleFor(
              widget.slip.type,
              isGu: _slipLocale == 'gu',
            ),
            sharePositionOrigin: origin,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.describeError(context.l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copyText() async {
    final text = _textFormatter.format(widget.slip, localeCode: _slipLocale);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppFeedback.showSuccess(context, context.l10n.slipCopiedMessage);
    }
  }

  Future<void> _printOrPdf() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final html = _htmlBuilder.buildHtml(widget.slip, localeCode: _slipLocale);
      final stamp = IstDateTimeHelper.formatIstFileTimestamp(
        widget.slip.transactionAtUtcMillis,
      );
      final jobName = 'StitchFlow_${widget.slip.type.name}_$stamp';
      final channel = getIt.isRegistered<AndroidReportPrintChannel>()
          ? getIt<AndroidReportPrintChannel>()
          : AndroidReportPrintChannel();
      await printReportHtmlPlatform(
        jobName: jobName,
        html: html,
        androidPrintChannel: channel,
        runWithPicker: (action) => _runWithPicker<bool>(action),
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.describeError(context.l10n, e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Language Switcher for Slip Output
          Row(
            children: [
              Expanded(
                child: AppText(
                  l10n.slipLanguageLabel,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                  ButtonSegment(
                    value: 'gu',
                    label: Text(l10n.languageGujarati),
                  ),
                ],
                selected: {_slipLocale},
                onSelectionChanged: (values) {
                  if (values.isNotEmpty) {
                    setState(() => _slipLocale = values.first);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Live Branded Slip Preview (captured by RepaintBoundary for PNG)
          RepaintBoundary(
            key: _repaintKey,
            child: SlipPreviewCard(slip: widget.slip, localeCode: _slipLocale),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3 Zero-Dependency Delivery Actions + Copy
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: l10n.slipShareImageAction,
                icon: AppIcons.image,
                isLoading: _busy,
                onPressed: _busy ? null : _sharePngImage,
              ),
              AppButton(
                label: l10n.slipShareTextAction,
                icon: AppIcons.share,
                variant: AppButtonVariant.secondary,
                onPressed: _busy ? null : _shareWhatsAppText,
              ),
              AppButton(
                label: l10n.slipCopyTextAction,
                icon: AppIcons.copy,
                variant: AppButtonVariant.outlined,
                onPressed: _busy ? null : _copyText,
              ),
              AppButton(
                label: l10n.slipPrintPdfAction,
                icon: AppIcons.print,
                variant: AppButtonVariant.outlined,
                onPressed: _busy ? null : _printOrPdf,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
