import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = MemberProcessRateResolver();

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  MemberProcessRateEntity makeRate({
    required String id,
    String memberId = 'w1',
    String processId = 'p1',
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
  }) {
    return MemberProcessRateEntity(
      id: id,
      memberId: memberId,
      processId: processId,
      ratePaise: ratePaise,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      createdAt: 1000,
      updatedAt: 1000,
    );
  }

  group('MemberProcessRateResolver — rate lookup', () {
    final rates = [
      makeRate(
        id: 'r1',
        ratePaise: 2000, // ₹20.00
        effectiveFrom: '2026-01-01',
        effectiveTo: '2026-11-30',
      ),
      makeRate(
        id: 'r2',
        ratePaise: 3000, // ₹30.00
        effectiveFrom: '2026-12-01',
        effectiveTo: null,
      ),
    ];

    test('returns missing before earliest effective_from date', () {
      final tx = DateTime.utc(2025, 12, 31, 10, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: rates,
      );
      expect(res, isA<RateResolutionMissing>());
      expect(res.businessDateIst, '2025-12-31');
    });

    test('matches exact effective_from boundary date', () {
      final tx = DateTime.utc(2026, 1, 1, 6, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: rates,
      );
      expect(res, isA<RateResolutionFound>());
      final found = res as RateResolutionFound;
      expect(found.rate.id, 'r1');
      expect(found.rate.ratePaise, 2000);
      expect(found.businessDateIst, '2026-01-01');
    });

    test('matches exact effective_to boundary date', () {
      // 2026-11-30 12:00 UTC = 2026-11-30 17:30 IST
      final tx = DateTime.utc(2026, 11, 30, 12, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: rates,
      );
      expect(res, isA<RateResolutionFound>());
      expect((res as RateResolutionFound).rate.ratePaise, 2000);
      expect(res.businessDateIst, '2026-11-30');
    });

    test('returns missing on day after effective_to when there is a gap', () {
      final closedOnly = [
        makeRate(
          id: 'r1',
          ratePaise: 2000,
          effectiveFrom: '2026-01-01',
          effectiveTo: '2026-11-30',
        ),
      ];
      final tx = DateTime.utc(2026, 12, 1, 6, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: closedOnly,
      );
      expect(res, isA<RateResolutionMissing>());
      expect(res.businessDateIst, '2026-12-01');
    });

    test('enforces Asia/Kolkata (IST) midnight boundary accurately', () {
      // 2026-11-30T18:29:59Z == 2026-11-30 23:59:59 IST -> ₹20
      final justBeforeMidnightIst = DateTime.utc(
        2026,
        11,
        30,
        18,
        29,
        59,
      ).millisecondsSinceEpoch;
      final beforeRes = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: justBeforeMidnightIst,
        rates: rates,
      );
      expect(beforeRes, isA<RateResolutionFound>());
      expect(beforeRes.businessDateIst, '2026-11-30');
      expect((beforeRes as RateResolutionFound).rate.ratePaise, 2000);

      // 2026-11-30T18:30:00Z == 2026-12-01 00:00:00 IST -> ₹30
      final exactMidnightIst = DateTime.utc(
        2026,
        11,
        30,
        18,
        30,
        0,
      ).millisecondsSinceEpoch;
      final midnightRes = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: exactMidnightIst,
        rates: rates,
      );
      expect(midnightRes, isA<RateResolutionFound>());
      expect(midnightRes.businessDateIst, '2026-12-01');
      expect((midnightRes as RateResolutionFound).rate.ratePaise, 3000);

      // 2026-11-30T19:00:00Z == 2026-12-01 00:30:00 IST -> ₹30
      final afterMidnightIst = DateTime.utc(
        2026,
        11,
        30,
        19,
        0,
        0,
      ).millisecondsSinceEpoch;
      final afterRes = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: afterMidnightIst,
        rates: rates,
      );
      expect(afterRes, isA<RateResolutionFound>());
      expect(afterRes.businessDateIst, '2026-12-01');
      expect((afterRes as RateResolutionFound).rate.ratePaise, 3000);
    });

    test('returns missing when no rate exists for worker/process pair', () {
      final tx = DateTime.utc(2026, 12, 5, 10, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w_other',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: rates,
      );
      expect(res, isA<RateResolutionMissing>());
    });

    test('rejects conflicting overlapping rate records during lookup', () {
      final conflicting = [
        makeRate(
          id: 'r1',
          ratePaise: 2000,
          effectiveFrom: '2026-01-01',
          effectiveTo: '2026-12-15',
        ),
        makeRate(
          id: 'r2',
          ratePaise: 3000,
          effectiveFrom: '2026-12-01',
          effectiveTo: null,
        ),
      ];
      final tx = DateTime.utc(2026, 12, 5, 10, 0).millisecondsSinceEpoch;
      final res = resolver.resolve(
        workerId: 'w1',
        processId: 'p1',
        transactionAtUtcMillis: tx,
        rates: conflicting,
      );
      expect(res, isA<RateResolutionConflict>());
      expect((res as RateResolutionConflict).conflictingRates.length, 2);
    });
  });

  group('MemberProcessRateResolver — range validation & date helpers', () {
    test('validates ISO dates and previousDayIso across boundaries', () {
      expect(resolver.isValidIsoDate('2026-12-01'), isTrue);
      expect(resolver.isValidIsoDate('2024-02-29'), isTrue);
      expect(resolver.isValidIsoDate('2026-02-29'), isFalse);
      expect(resolver.isValidIsoDate('2026-02-30'), isFalse);
      expect(resolver.isValidIsoDate('01-12-2026'), isFalse);

      expect(resolver.previousDayIso('2026-12-01'), '2026-11-30');
      expect(resolver.previousDayIso('2026-01-01'), '2025-12-31');
      expect(resolver.previousDayIso('2024-03-01'), '2024-02-29');
    });

    test(
      'rejects overlapping, inverted, negative, and duplicate open rates',
      () {
        final existing = [
          makeRate(
            id: 'r1',
            ratePaise: 2000,
            effectiveFrom: '2026-01-01',
            effectiveTo: '2026-11-30',
          ),
          makeRate(
            id: 'r2',
            ratePaise: 3000,
            effectiveFrom: '2026-12-01',
            effectiveTo: null,
          ),
        ];

        expect(
          resolver
              .validateCandidateRate(
                ratePaise: -100,
                effectiveFrom: '2027-01-01',
                existingRates: existing,
              )
              .errorCode,
          RateValidationErrorCode.negativeRate,
        );

        expect(
          resolver
              .validateCandidateRate(
                ratePaise: 2500,
                effectiveFrom: '2026-10-10',
                effectiveTo: '2026-10-05',
                existingRates: const [],
              )
              .errorCode,
          RateValidationErrorCode.effectiveToBeforeFrom,
        );

        expect(
          resolver
              .validateCandidateRate(
                ratePaise: 2500,
                effectiveFrom: '2026-11-15',
                effectiveTo: '2026-11-20',
                existingRates: existing,
              )
              .errorCode,
          RateValidationErrorCode.overlappingPeriod,
        );

        expect(
          resolver
              .validateCandidateRate(
                ratePaise: 3500,
                effectiveFrom: '2027-01-01',
                effectiveTo: null,
                existingRates: existing,
              )
              .errorCode,
          RateValidationErrorCode.multipleOpenEndedRates,
        );

        // Valid when auto-closing the open-ended r2
        final autoCloseResult = resolver.validateCandidateRate(
          ratePaise: 3500,
          effectiveFrom: '2027-01-01',
          effectiveTo: null,
          existingRates: existing,
          autoCloseRateId: 'r2',
        );
        expect(autoCloseResult.isValid, isTrue);
      },
    );
  });
}
