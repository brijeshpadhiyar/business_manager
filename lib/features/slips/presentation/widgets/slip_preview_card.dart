import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/domain/services/slip_text_formatter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/widgets/widgets.dart';

/// Branded Indigo Thread receipt card rendered in Flutter (with bundled
/// `NotoSansGujarati` shaping) and wrapped in a [RepaintBoundary] by
/// [SlipShareSheet] for crisp zero-dependency PNG image capture.
final class SlipPreviewCard extends StatelessWidget {
  const SlipPreviewCard({
    super.key,
    required this.slip,
    required this.localeCode,
  });

  final WorkerSlipData slip;
  final String localeCode;

  static const SlipTextFormatter _formatter = SlipTextFormatter();

  @override
  Widget build(BuildContext context) {
    final isGu = localeCode == 'gu';
    final shop = slip.shopNameForLocale(localeCode);
    final title = _formatter.titleFor(slip.type, isGu: isGu);
    final dateStr = IstDateTimeHelper.formatIstDateTime(
      slip.transactionAtUtcMillis,
      locale: localeCode,
    );
    final period = slip.periodForLocale(localeCode);

    final balanceLabel = slip.outstandingPayablePaise > 0
        ? (isGu ? 'બાકી ચૂકવવાપાત્ર' : 'Outstanding Payable')
        : slip.advanceCreditPaise > 0
        ? (isGu ? 'એડવાન્સ જમા' : 'Advance Credit')
        : (isGu ? 'હિસાબ ચોખ્ખો' : 'Account Settled');
    final balanceValue = slip.outstandingPayablePaise > 0
        ? MoneyFormatter.formatPaise(slip.outstandingPayablePaise)
        : slip.advanceCreditPaise > 0
        ? MoneyFormatter.formatPaise(slip.advanceCreditPaise)
        : MoneyFormatter.formatPaise(0);

    return Material(
      color: Colors.white,
      borderRadius: AppRadius.lgBorder,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.indigo600, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Indigo Thread Header Banner
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradientLight,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shop,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'NotoSansGujarati',
                          ),
                        ),
                        if (slip.businessPhone != null &&
                            slip.businessPhone!.isNotEmpty)
                          Text(
                            slip.businessPhone!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              fontFamily: 'NotoSansGujarati',
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.emerald600,
                      borderRadius: AppRadius.fullBorder,
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'NotoSansGujarati',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Metadata + Line Items + Balance
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGu ? 'કારીગર' : 'Worker',
                              style: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 10.5,
                                fontFamily: 'NotoSansGujarati',
                              ),
                            ),
                            Text(
                              slip.workerName,
                              style: const TextStyle(
                                color: AppColors.slate900,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'NotoSansGujarati',
                              ),
                            ),
                            if (slip.workerPhone != null &&
                                slip.workerPhone!.isNotEmpty)
                              Text(
                                slip.workerPhone!,
                                style: const TextStyle(
                                  color: AppColors.slate600,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isGu ? 'સંદર્ભ' : 'Ref'}: ${slip.referenceId}',
                            style: const TextStyle(
                              color: AppColors.slate900,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'NotoSansGujarati',
                            ),
                          ),
                          Text(
                            '$dateStr (IST)',
                            style: const TextStyle(
                              color: AppColors.slate600,
                              fontSize: 10.5,
                            ),
                          ),
                          if (period != null && period.isNotEmpty)
                            Text(
                              period,
                              style: const TextStyle(
                                color: AppColors.indigo600,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: AppDivider(color: AppColors.slate200, height: 1),
                  ),

                  for (final item in slip.items.take(15)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: AppColors.slate900,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'NotoSansGujarati',
                                  ),
                                ),
                                if (item.subtitle != null &&
                                    item.subtitle!.isNotEmpty)
                                  Text(
                                    item.subtitle!,
                                    style: const TextStyle(
                                      color: AppColors.slate600,
                                      fontSize: 11,
                                      fontFamily: 'NotoSansGujarati',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (item.quantityText != null)
                                Text(
                                  item.quantityText!,
                                  style: const TextStyle(
                                    color: AppColors.slate800,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (item.rateText != null)
                                Text(
                                  item.rateText!,
                                  style: const TextStyle(
                                    color: AppColors.slate600,
                                    fontSize: 10.5,
                                  ),
                                ),
                              if (item.amountPaise != null)
                                Text(
                                  MoneyFormatter.formatPaise(item.amountPaise!),
                                  style: const TextStyle(
                                    color: AppColors.indigo700,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: AppDivider(color: AppColors.slate200, height: 1),
                  ),

                  if (slip.primaryAmountPaise != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.indigo50,
                        borderRadius: AppRadius.smBorder,
                        border: Border(
                          left: BorderSide(
                            color: AppColors.indigo600,
                            width: 3.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isGu ? 'કુલ રકમ' : 'Slip Total',
                            style: const TextStyle(
                              color: AppColors.indigo900,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'NotoSansGujarati',
                            ),
                          ),
                          Text(
                            MoneyFormatter.formatPaise(
                              slip.primaryAmountPaise!,
                            ),
                            style: const TextStyle(
                              color: AppColors.indigo900,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: AppRadius.smBorder,
                      border: Border(
                        left: BorderSide(
                          color: slip.outstandingPayablePaise > 0
                              ? AppColors.saffron500
                              : AppColors.emerald600,
                          width: 3.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          balanceLabel,
                          style: const TextStyle(
                            color: AppColors.slate800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'NotoSansGujarati',
                          ),
                        ),
                        Text(
                          balanceValue,
                          style: const TextStyle(
                            color: AppColors.slate900,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (slip.notes != null && slip.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${isGu ? 'નોંધ' : 'Note'}: ${slip.notes!.trim()}',
                      style: const TextStyle(
                        color: AppColors.slate600,
                        fontSize: 11,
                        fontFamily: 'NotoSansGujarati',
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGu
                            ? 'StitchFlow ઓફલાઇન રસીદ'
                            : 'StitchFlow Offline Slip',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 10,
                          fontFamily: 'NotoSansGujarati',
                        ),
                      ),
                      Text(
                        isGu ? 'સહી: ____________' : 'Signature: ____________',
                        style: const TextStyle(
                          color: AppColors.slate500,
                          fontSize: 10,
                          fontFamily: 'NotoSansGujarati',
                        ),
                      ),
                    ],
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
