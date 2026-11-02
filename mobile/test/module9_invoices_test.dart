import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:room_rental_mobile/core/services/invoice_service.dart';

Map<String, dynamic> _invoiceJson({
  int id = 12,
  String status = 'PENDING',
  num total = 3500000,
  num paid = 0,
  num deduction = 0,
  num? remaining,
  String month = '2026-04-01',
  int roomId = 5,
  String roomNumber = '101',
}) =>
    {
      'id': id,
      'contractId': 7,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'billingMonth': month,
      'totalAmount': total,
      'paidAmount': paid,
      'balanceDeduction': deduction,
      if (remaining != null) 'remainingAmount': remaining,
      'status': status,
      'invoiceType': 'MONTHLY',
      'dueDate': '2026-04-06',
      'calculationSnapshot': jsonEncode({
        'replacesInvoiceId': 9,
        'items': [
          {'serviceId': null, 'serviceName': 'Tiền phòng', 'chargeType': 'FIXED', 'basePrice': 3000000},
          {
            'serviceId': 2,
            'serviceName': 'Điện',
            'chargeType': 'PER_INDEX',
            'oldReading': 100,
            'newReading': 150,
            'basePrice': 3500,
          },
        ],
      }),
      'details': [
        {'id': 1, 'description': 'Tiền phòng', 'quantity': 1, 'unitPrice': 3000000, 'lineTotal': 3000000, 'serviceId': null},
        {'id': 2, 'description': 'Điện', 'quantity': 50, 'unitPrice': 3500, 'lineTotal': 175000, 'serviceId': 2},
        {'id': 3, 'description': 'Internet', 'quantity': 1, 'unitPrice': 100000, 'lineTotal': 100000, 'serviceId': 4},
        {'id': 4, 'description': 'Phụ thu: Sửa khóa', 'quantity': 1, 'unitPrice': 225000, 'lineTotal': 225000, 'serviceId': null},
      ],
    };

void main() {
  group('formatVnd / parse', () {
    test('định dạng VND có dấu chấm hàng nghìn, làm tròn', () {
      expect(formatVnd(1500000), '1.500.000đ');
      expect(formatVnd(0), '0đ');
      expect(formatVnd(999.6), '1.000đ');
      expect(formatVnd(-25000), '-25.000đ');
      expect(formatVnd(5200000, withSymbol: false), '5.200.000');
    });

    test('đọc số tiền người dùng nhập', () {
      expect(parseVndInput('1.500.000'), 1500000);
      expect(parseVndInput('200000đ'), 200000);
      expect(parseVndInput(''), isNull);
    });

    test('kỳ và ngày', () {
      expect(formatBillingMonth('2026-04-01'), 'Tháng 4/2026');
      expect(formatBillingMonth('2026-04'), 'Tháng 4/2026');
      expect(formatDateVi('2026-04-06'), '06/04/2026');
      expect(billingMonthKey(DateTime(2026, 3)), '2026-03');
      expect(invoiceStatusLabel('PARTIAL'), 'Thanh toán một phần');
    });
  });

  group('InvoiceResult.fromJson', () {
    test('parse đầy đủ trường, remaining từ máy chủ', () {
      final inv = InvoiceResult.fromJson(_invoiceJson(paid: 1000000, remaining: 2500000, status: 'PARTIAL'));
      expect(inv.id, 12);
      expect(inv.roomLabel, 'Phòng 101');
      expect(inv.details.length, 4);
      expect(inv.remainingAmount, 2500000);
      expect(inv.isUnpaid, isTrue);
      expect(inv.canAdjust, isFalse);
      expect(inv.replacesInvoiceId, 9);
      expect(inv.details.last.isAdjustment, isTrue);
    });

    test('remaining tự tính khi thiếu = tổng - đã trả - khấu trừ, không âm', () {
      final inv = InvoiceResult.fromJson(_invoiceJson(total: 1000, paid: 300, deduction: 200));
      expect(inv.remainingAmount, 500);
      final over = InvoiceResult.fromJson(_invoiceJson(total: 1000, paid: 1200, status: 'PAID'));
      expect(over.remainingAmount, 0);
    });

    test('chấp nhận số dạng chuỗi và thiếu trường', () {
      final inv = InvoiceResult.fromJson({'id': '3', 'totalAmount': '120000', 'details': null});
      expect(inv.id, 3);
      expect(inv.totalAmount, 120000);
      expect(inv.status, 'PENDING');
      expect(inv.canDelete, isTrue);
    });

    test('ghép chỉ số điện từ snapshot vào bảng kê', () {
      final lines = buildInvoiceLines(InvoiceResult.fromJson(_invoiceJson()));
      final dien = lines.firstWhere((l) => l.name == 'Điện');
      expect(dien.isMeter, isTrue);
      expect(dien.oldReading, 100);
      expect(dien.newReading, 150);
      expect(dien.consumption, 50);
      expect(lines.firstWhere((l) => l.name == 'Tiền phòng').isMeter, isFalse);
    });
  });

  group('Kết quả tạo hóa đơn & giao dịch', () {
    test('InvoiceGenerationResult phân loại phòng bị bỏ qua', () {
      final r = InvoiceGenerationResult.fromJson({
        'invoices': [_invoiceJson()],
        'skippedRooms': [
          {'roomId': 1, 'roomNumber': '102', 'reason': 'Thiếu chỉ số điện/nước đã duyệt (APPROVED)'},
          {'roomId': 2, 'roomNumber': '103', 'reason': 'Đã có hóa đơn cho kỳ này'},
          {'roomId': 3, 'roomNumber': '104', 'reason': 'Lỗi: timeout'},
        ],
      });
      expect(r.createdCount, 1);
      expect(r.missingReadingRooms.single.roomNumber, '102');
      expect(r.alreadyInvoicedRooms.single.roomNumber, '103');
      expect(r.errorRooms.single.roomNumber, '104');
      expect(InvoiceGenerationResult.fromJson(null).createdCount, 0);
    });

    test('TransactionResult.fromJson và lọc/tìm kiếm', () {
      final txs = [
        TransactionResult.fromJson({
          'id': 1, 'invoiceId': 12, 'amount': 3500000, 'overpaidAmount': 0, 'transactionRef': 'FT2604ABC',
          'paymentMethod': 'VIETQR', 'bankCode': 'ICB', 'status': 'SUCCESS', 'paidAt': '2026-04-03T10:00:00+07:00',
        }),
        TransactionResult.fromJson({
          'id': 2, 'invoiceId': 13, 'amount': 500000, 'overpaidAmount': 50000, 'transactionRef': 'MANUAL-1a2b',
          'paymentMethod': 'CASH', 'status': 'SUCCESS', 'paidAt': '2026-05-03T10:00:00+07:00',
        }),
        TransactionResult.fromJson({
          'id': 3, 'invoiceId': null, 'amount': 200000, 'transactionRef': 'FT999', 'paymentMethod': 'VIETQR',
          'status': 'PENDING_RECONCILE', 'paidAt': '2026-05-10T10:00:00+07:00',
        }),
      ];
      expect(txs[1].isOverpaid, isTrue);
      expect(txs[2].needsReconcile, isTrue);
      expect(filterTransactions(txs, query: 'ft2604').single.id, 1);
      expect(filterTransactions(txs, query: '#13').single.id, 2);
      expect(filterTransactions(txs, method: 'CASH').single.id, 2);
      expect(filterTransactions(txs, status: 'PENDING_RECONCILE').single.id, 3);
      expect(filterTransactions(txs, from: DateTime(2026, 5, 1), to: DateTime(2026, 5, 5)).single.id, 2);
      final csv = buildTransactionsCsv(txs);
      expect(csv.split('\n').where((l) => l.trim().isNotEmpty).length, 4);
      expect(csv, contains('Tiền mặt'));
      expect(paymentMethodLabel('BANK_TRANSFER'), 'Chuyển khoản');
      expect(describePaymentOutcome(100, 300), contains('một phần'));
      expect(describePaymentOutcome(400, 300), contains('số dư'));
    });
  });

  group('Lọc & tổng hợp danh sách', () {
    final list = [
      InvoiceResult.fromJson(_invoiceJson(id: 1, status: 'PAID', total: 1000, paid: 1000, month: '2026-03-01')),
      InvoiceResult.fromJson(_invoiceJson(id: 2, status: 'PARTIAL', total: 2000, paid: 500, roomId: 6, roomNumber: '202')),
      InvoiceResult.fromJson(_invoiceJson(id: 3, status: 'VOID', total: 9000)),
    ];

    test('lọc theo trạng thái, tháng, phòng và từ khóa', () {
      expect(filterInvoices(list, status: 'PARTIAL').single.id, 2);
      expect(filterInvoices(list, billingMonth: '2026-03').single.id, 1);
      expect(filterInvoices(list, roomId: 6).single.id, 2);
      expect(filterInvoices(list, query: '202').single.id, 2);
      expect(filterInvoices(list, query: '#3').single.id, 3);
    });

    test('tổng tiền / đã trả / còn lại bỏ qua hóa đơn đã hủy', () {
      final t = InvoiceTotals.of(list);
      expect(t.count, 2);
      expect(t.total, 3000);
      expect(t.paid, 1500);
      expect(t.remaining, 1500);
    });
  });

  group('Tính lại tổng khi điều chỉnh (UC76)', () {
    final lines = buildInvoiceLines(InvoiceResult.fromJson(_invoiceJson()));

    test('không thay đổi → tổng giữ nguyên', () {
      final c = InvoiceAdjustmentCalculator(lines: lines);
      expect(c.originalTotal, 3500000);
      expect(c.newTotal, 3500000);
      expect(c.hasChanges, isFalse);
    });

    test('thêm phụ thu và giảm trừ', () {
      final c = InvoiceAdjustmentCalculator(lines: lines, adjustments: const [
        InvoiceAdjustmentItem(description: 'Vệ sinh', amount: 50000),
        InvoiceAdjustmentItem(description: 'Giảm giá Tết', amount: -200000),
      ]);
      expect(c.newTotal, 3350000);
      expect(c.difference, -150000);
      expect(c.hasChanges, isTrue);
      expect(c.adjustments.last.toJson(), {'description': 'Giảm giá Tết', 'amount': -200000});
    });

    test('sửa số tiền một dòng và sửa chỉ số điện', () {
      final c = InvoiceAdjustmentCalculator(
        lines: lines,
        editedAmounts: const {3: 80000},
        correctedReadings: const {2: 140},
      );
      // Internet 100k → 80k (-20k); điện 50 → 40 số × 3.500 (-35k)
      expect(c.newTotal, 3445000);
      expect(c.isApproximate, isFalse);
    });

    test('kiểm tra hợp lệ: lý do bắt buộc, chỉ số không nhỏ hơn cũ, mô tả, tổng không âm', () {
      expect(const InvoiceAdjustmentCalculator(lines: []).validate(' '), isNotNull);
      expect(InvoiceAdjustmentCalculator(lines: lines, correctedReadings: const {2: 90}).validate('Sai số'), contains('không được nhỏ hơn'));
      expect(
        InvoiceAdjustmentCalculator(lines: lines, adjustments: const [InvoiceAdjustmentItem(description: '', amount: 1000)])
            .validate('x'),
        contains('mô tả'),
      );
      expect(
        InvoiceAdjustmentCalculator(lines: lines, adjustments: const [InvoiceAdjustmentItem(description: 'Giảm', amount: -9000000)])
            .validate('x'),
        contains('âm'),
      );
      expect(InvoiceAdjustmentCalculator(lines: lines, correctedReadings: const {2: 160}).validate('Sai số'), isNull);
    });
  });
}
