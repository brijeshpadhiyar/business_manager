import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:material_ui/material_ui.dart';

/// Lightweight zero-dependency StitchFlow dual-bar trend chart (`Issued` vs `Good Returned`)
/// rendered with `CustomPainter`, fully Light & Dark theme aware and 360dp-safe.
final class ReportTrendChart extends StatelessWidget {
  const ReportTrendChart({
    super.key,
    required this.points,
    required this.issuedLabel,
    required this.goodReturnedLabel,
    this.height = 176,
  });

  final List<ProductionTrendPoint> points;
  final String issuedLabel;
  final String goodReturnedLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final issuedColor = isDark
        ? AppColors.darkAdvanceCredit
        : AppColors.brandNavyMid;
    final goodColor = isDark ? AppColors.darkGoodStock : AppColors.brandTeal;
    final gridColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;

    // Show at most the 14 most recent buckets so bars stay readable on 360dp
    final visible = points.length > 14
        ? points.sublist(points.length - 14)
        : points;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: [
            _LegendDot(color: issuedColor, label: issuedLabel),
            _LegendDot(color: goodColor, label: goodReturnedLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _DualBarChartPainter(
              points: visible,
              issuedColor: issuedColor,
              goodColor: goodColor,
              gridColor: gridColor,
              labelColor: labelColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

final class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        AppText(label, variant: AppTextVariant.label),
      ],
    );
  }
}

final class _DualBarChartPainter extends CustomPainter {
  _DualBarChartPainter({
    required this.points,
    required this.issuedColor,
    required this.goodColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<ProductionTrendPoint> points;
  final Color issuedColor;
  final Color goodColor;
  final Color gridColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;

    const double bottomLabelHeight = 24;
    const double topPad = 10;
    const double leftPad = 34;
    const double rightPad = 8;

    final chartWidth = math.max(1.0, size.width - leftPad - rightPad);
    final chartHeight = math.max(1.0, size.height - bottomLabelHeight - topPad);

    var maxVal = 0;
    for (final p in points) {
      if (p.issuedQty > maxVal) maxVal = p.issuedQty;
      if (p.goodReturnedQty > maxVal) maxVal = p.goodReturnedQty;
    }
    if (maxVal <= 0) maxVal = 1;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    // Draw 3 horizontal gridlines (0%, 50%, 100%)
    for (final fraction in [0.0, 0.5, 1.0]) {
      final y = topPad + chartHeight * (1 - fraction);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(leftPad + chartWidth, y),
        gridPaint,
      );
      final tickVal = (maxVal * fraction).round();
      final tp = TextPainter(
        text: TextSpan(
          text: '$tickVal',
          style: TextStyle(color: labelColor, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 4);
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final slotWidth = chartWidth / points.length;
    final barPairWidth = math.min(slotWidth * 0.72, 26.0);
    final singleBarWidth = math.max(2.0, (barPairWidth - 2) / 2);

    final issuedPaint = Paint()..color = issuedColor;
    final goodPaint = Paint()..color = goodColor;

    // Label stride so x-axis never collides on 360dp
    final labelStep = points.length <= 7 ? 1 : (points.length <= 10 ? 2 : 3);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final slotCenter = leftPad + slotWidth * i + slotWidth / 2;

      final issuedH = (p.issuedQty / maxVal) * chartHeight;
      final goodH = (p.goodReturnedQty / maxVal) * chartHeight;

      final baseY = topPad + chartHeight;
      final leftBarX = slotCenter - singleBarWidth - 1;
      final rightBarX = slotCenter + 1;

      if (issuedH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(leftBarX, baseY - issuedH, singleBarWidth, issuedH),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          issuedPaint,
        );
      }
      if (goodH > 0) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(rightBarX, baseY - goodH, singleBarWidth, goodH),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
          ),
          goodPaint,
        );
      }

      if (i % labelStep == 0 || i == points.length - 1) {
        final tp = TextPainter(
          text: TextSpan(
            text: p.label,
            style: TextStyle(color: labelColor, fontSize: 9.5),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 44);
        final lx = (slotCenter - tp.width / 2).clamp(
          leftPad,
          size.width - tp.width,
        );
        tp.paint(canvas, Offset(lx, baseY + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DualBarChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.issuedColor != issuedColor ||
        oldDelegate.goodColor != goodColor ||
        oldDelegate.gridColor != gridColor;
  }
}
