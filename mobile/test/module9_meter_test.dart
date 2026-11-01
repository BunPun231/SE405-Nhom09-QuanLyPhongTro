import 'package:flutter_test/flutter_test.dart';
import 'package:room_rental_mobile/core/services/meter_reading_service.dart';

MeterReading _r({
  int id = 1,
  int roomId = 10,
  int serviceId = 1,
  String month = '2026-06-01',
  double old = 0,
  double? newR,
  String status = 'APPROVED',
}) =>
    MeterReading(
      id: id,
      roomId: roomId,
      serviceId: serviceId,
      serviceName: 'Điện',
      billingMonth: month,
      oldReading: old,
      newReading: newR,
      status: status,
    );

void main() {
  group('MeterReading.fromJson', () {
    test('parses backend MeterReadingResult', () {
      final r = MeterReading.fromJson({
        'id': 5,
        'roomId': 12,
        'serviceId': 3,
        'serviceName': 'Nước',
        'billingMonth': '2026-06-01',
        'oldReading': 100,
        'newReading': 112.5,
        'consumption': 12.5,
        'status': 'REJECTED',
        'readingImageUrl': 'https://img/a.jpg',
        'ocrConfidence': 0.82,
        'rejectReason': 'Ảnh mờ',
        'createdAt': '2026-06-02T08:00:00Z',
      });
      expect(r.id, 5);
      expect(r.roomId, 12);
      expect(r.serviceName, 'Nước');
      expect(r.monthKey, '2026-06');
      expect(r.consumption, 12.5);
      expect(r.isRejected, isTrue);
      expect(r.imageUrl, 'https://img/a.jpg');
      expect(r.ocrConfidence, closeTo(82, 0.001));
      expect(r.rejectReason, 'Ảnh mờ');
      expect(r.createdAt, isNotNull);
    });

    test('computes consumption when backend returns null and tolerates strings', () {
      final r = MeterReading.fromJson({
        'id': '7',
        'roomId': 1,
        'serviceId': 2,
        'billingMonth': '2026-05-01',
        'oldReading': '50',
        'newReading': 80,
        'consumption': null,
        'status': 'PENDING',
        'readingImageUrl': '',
        'rejectReason': '  ',
      });
      expect(r.id, 7);
      expect(r.consumption, 30);
      expect(r.isPending, isTrue);
      expect(r.imageUrl, isNull);
      expect(r.rejectReason, isNull);
      expect(r.ocrConfidence, isNull);
    });

    test('SUBMITTED is treated as pending', () {
      expect(MeterStatus.isPending('SUBMITTED'), isTrue);
      expect(MeterStatus.label('PENDING'), 'Chờ duyệt');
      expect(MeterStatus.label(null), 'Chưa ghi');
    });
  });

  group('OCR', () {
    test('suggestion parses and normalises confidence', () {
      final s = OcrSuggestion.fromJson({'newReading': 1234, 'ocrConfidence': 95.0, 'oldReading': 1200});
      expect(s.value, 1234);
      expect(s.confidence, 95);
      expect(s.oldReading, 1200);
      expect(s.needsReview, isFalse);
      expect(s.isLowConfidence, isFalse);
    });

    test('confidence thresholds: <90 needs review, <70 is low', () {
      expect(MeterRules.needsReview(89.9), isTrue);
      expect(MeterRules.needsReview(90), isFalse);
      expect(MeterRules.isLowConfidence(69), isTrue);
      expect(MeterRules.isLowConfidence(70), isFalse);
      final s = OcrSuggestion.fromJson({'newReading': 10, 'ocrConfidence': 0.85});
      expect(s.confidence, closeTo(85, 0.001));
      expect(s.needsReview, isTrue);
    });

    test('normalizeConfidence handles 0-1, 0-100, null and overflow', () {
      expect(MeterRules.normalizeConfidence(null), 0);
      expect(MeterRules.normalizeConfidence(0.5), 50);
      expect(MeterRules.normalizeConfidence(1), 100);
      expect(MeterRules.normalizeConfidence(85), 85);
      expect(MeterRules.normalizeConfidence(150), 100);
      expect(MeterRules.normalizeConfidence(-3), 0);
    });

    test('timeout is 5 seconds', () {
      expect(MeterRules.ocrTimeout, const Duration(seconds: 5));
      expect(OcrTimeoutException().toString(), contains('nhập'));
    });

    test('sanitizeReading strips units and noise', () {
      expect(MeterRules.sanitizeReading('01234 kWh'), 1234);
      expect(MeterRules.sanitizeReading('Chỉ số: 56,7 m3'), 56.7);
      expect(MeterRules.sanitizeReading('abc'), isNull);
      expect(MeterRules.sanitizeReading(null), isNull);
    });

    test('image resolution check 640x480 in both orientations', () {
      expect(MeterRules.isImageResolutionOk(640, 480), isTrue);
      expect(MeterRules.isImageResolutionOk(480, 640), isTrue);
      expect(MeterRules.isImageResolutionOk(600, 480), isFalse);
      expect(MeterRules.isImageResolutionOk(1600, 400), isFalse);
    });
  });

  group('Validation', () {
    test('new reading must be >= old reading', () {
      expect(MeterRules.validateNewReading(100, ''), isNotNull);
      expect(MeterRules.validateNewReading(100, 'abc'), 'Chỉ số không hợp lệ');
      expect(MeterRules.validateNewReading(100, '99'), contains('lớn hơn hoặc bằng'));
      expect(MeterRules.validateNewReading(100, '100'), isNull);
      expect(MeterRules.validateNewReading(100, '120,5'), isNull);
      expect(MeterRules.validateNewReading(null, '5'), isNull);
    });

    test('parseInput rejects negatives', () {
      expect(MeterRules.parseInput('-1'), isNull);
      expect(MeterRules.parseInput(' 12 '), 12);
    });
  });

  group('Consumption', () {
    final readings = [
      _r(id: 1, month: '2026-02-01', old: 0, newR: 100),
      _r(id: 2, month: '2026-03-01', old: 100, newR: 200),
      _r(id: 3, month: '2026-04-01', old: 200, newR: 320),
      _r(id: 4, month: '2026-05-01', old: 320, newR: 410),
      _r(id: 5, month: '2026-06-01', old: 410, newR: 600, status: 'PENDING'),
      _r(id: 6, month: '2026-05-01', old: 0, newR: 999, serviceId: 2),
      _r(id: 7, month: '2026-05-01', old: 0, newR: 999, roomId: 11),
    ];

    test('average of last 3 approved months before the given month', () {
      final avg = MeterRules.averageConsumption(readings, roomId: 10, serviceId: 1, beforeMonthKey: '2026-06');
      expect(avg, closeTo((100 + 120 + 90) / 3, 0.001));
      expect(
        MeterRules.averageConsumption(readings, roomId: 10, serviceId: 1, beforeMonthKey: '2026-02'),
        isNull,
      );
    });

    test('high consumption over 130% of average', () {
      expect(MeterRules.isHighConsumption(190, 100), isTrue);
      expect(MeterRules.isHighConsumption(130, 100), isFalse);
      expect(MeterRules.isHighConsumption(190, null), isFalse);
      expect(MeterRules.isHighConsumption(null, 100), isFalse);
    });

    test('trend is approved-only, ascending, capped', () {
      final trend = MeterRules.buildTrend(readings.where((r) => r.roomId == 10).toList(), serviceId: 1);
      expect(trend.map((p) => p.monthKey), ['2026-02', '2026-03', '2026-04', '2026-05']);
      expect(trend.map((p) => p.consumption), [100, 100, 120, 90]);
      final capped = MeterRules.buildTrend(readings.where((r) => r.roomId == 10).toList(), serviceId: 1, maxMonths: 2);
      expect(capped.map((p) => p.monthKey), ['2026-04', '2026-05']);
    });

    test('meter reset is flagged and plotted as zero', () {
      final reset = _r(month: '2026-07-01', old: 900, newR: 15);
      expect(reset.isMeterReset, isTrue);
      final p = MeterRules.buildTrend([reset]).single;
      expect(p.meterReset, isTrue);
      expect(p.consumption, 0);
    });

    test('official history hides non-approved and sorts newest first', () {
      final h = MeterRules.officialHistory(readings.where((r) => r.serviceId == 1 && r.roomId == 10).toList());
      expect(h.first.monthKey, '2026-05');
      expect(h.every((r) => r.isApproved), isTrue);
      expect(h.length, 4);
    });
  });

  group('Formatting', () {
    test('formatReading groups thousands and trims decimals', () {
      expect(MeterRules.formatReading(1234567), '1.234.567');
      expect(MeterRules.formatReading(12.5), '12,5');
      expect(MeterRules.formatReading(null), '—');
      expect(MeterRules.formatReading(0), '0');
    });

    test('month labels and helpers', () {
      expect(MeterRules.monthLabel('2026-06-01'), 'Tháng 6/2026');
      expect(MeterRules.shortMonthLabel('2026-11'), 'T11/26');
      expect(MeterRules.monthKeyOf(DateTime(2026, 3, 9)), '2026-03');
      expect(MeterRules.isElectric('Tiền điện'), isTrue);
      expect(MeterRules.isElectric('Nước'), isFalse);
      expect(MeterRules.mimeTypeFor('a.PNG'), 'image/png');
      expect(MeterRules.mimeTypeFor('a.jpg'), 'image/jpeg');
    });
  });
}
