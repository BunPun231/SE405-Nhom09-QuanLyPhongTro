import 'package:flutter_test/flutter_test.dart';
import 'package:room_rental_mobile/core/services/contract_service.dart';
import 'package:room_rental_mobile/core/services/settlement_service.dart';
import 'package:room_rental_mobile/presentation/screens/manager/contracts/contract_ui.dart';

void main() {
  group('UC63 – điều khoản hợp đồng', () {
    test('ngày kết thúc phải sau ngày bắt đầu', () {
      final s = DateTime(2026, 6, 1);
      expect(ContractRules.validateTerms(start: s, end: s, rent: 1, deposit: 1).ok, isFalse);
      expect(ContractRules.validateTerms(start: s, end: DateTime(2026, 5, 1), rent: 1, deposit: 1).error,
          'Ngày kết thúc phải sau ngày bắt đầu');
      expect(ContractRules.validateTerms(start: s, end: DateTime(2027, 6, 1), rent: 3000000, deposit: 3000000).ok, isTrue);
    });

    test('giá thuê và tiền cọc phải dương', () {
      final s = DateTime(2026, 6, 1);
      final e = DateTime(2027, 6, 1);
      expect(ContractRules.validateTerms(start: s, end: e, rent: 0, deposit: 1).ok, isFalse);
      expect(ContractRules.validateTerms(start: s, end: e, rent: 1, deposit: null).ok, isFalse);
    });

    test('cộng tháng kẹp cuối tháng và tính thời hạn', () {
      expect(ContractRules.addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
      expect(ContractRules.addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
      expect(ContractRules.durationMonths(DateTime(2026, 6, 1), DateTime(2027, 6, 1)), 12);
      expect(ContractRules.durationMonths(DateTime(2026, 6, 15), DateTime(2026, 7, 14)), 0);
    });

    test('tiền phòng lẻ ngày kỳ đầu (BR90) làm tròn hàng nghìn', () {
      // Bắt đầu 21/06, chốt cuối tháng → 10 ngày; 3.000.000/30*10 = 1.000.000
      final pro = ContractRules.proRatedFirstRent(start: DateTime(2026, 6, 21), rent: 3000000, billingCycleDay: 31)!;
      expect(pro.days, 10);
      expect(pro.amount, 1000000);
      // 3.500.000/30*7 = 816.666 → 817.000
      final pro2 = ContractRules.proRatedFirstRent(start: DateTime(2026, 6, 24), rent: 3500000)!;
      expect(pro2.days, 7);
      expect(pro2.amount, 817000);
    });

    test('bắt đầu đúng đầu kỳ thì không tính lẻ ngày', () {
      expect(ContractRules.proRatedFirstRent(start: DateTime(2026, 6, 1), rent: 3000000), isNull);
      expect(ContractRules.proRatedFirstRent(start: DateTime(2026, 6, 6), rent: 3000000, billingCycleDay: 5), isNull);
      final pro = ContractRules.proRatedFirstRent(start: DateTime(2026, 6, 1), rent: 3000000, billingCycleDay: 5)!;
      expect(pro.days, 5);
    });

    test('body tạo hợp đồng khớp backend', () {
      final body = ContractService.buildCreateBody(
        roomId: 7,
        newResidentFullName: 'Nguyễn Văn A',
        newResidentPhone: '0909123456',
        newResidentIdCard: '079123456789',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 6, 1),
        rentPrice: 3500000,
        depositAmount: 3500000,
      );
      expect(body['startDate'], '2026-06-01');
      expect(body['primaryResidentPhone'], '0909123456');
      expect(body.containsKey('primaryResidentUserId'), isFalse);
      expect(body['depositStatus'], 'UNPAID');
      final existing = ContractService.buildCreateBody(
        roomId: 7,
        residentUserId: 'u-1',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2027, 6, 1),
        rentPrice: 1,
        depositAmount: 1,
      );
      expect(existing['primaryResidentUserId'], 'u-1');
      expect(existing.containsKey('primaryResidentPhone'), isFalse);
    });
  });

  group('UC64/UC65 – parse JSON và hiển thị', () {
    test('ContractResult parse số dạng chuỗi/thập phân', () {
      final c = ContractResult.fromJson({
        'id': 12,
        'tenantId': 't',
        'roomId': 3,
        'primaryResidentUserId': 'u',
        'rentPrice': 3500000.00,
        'startDate': '2026-06-01',
        'endDate': '2027-06-01',
        'depositAmount': '3500000',
        'depositStatus': 'PAID',
        'status': 'ACTIVE',
      });
      expect(c.rentPrice, 3500000);
      expect(c.depositAmount, 3500000);
      expect(c.displayCode, 'HĐ-12');
    });

    test('ContractDetailResult đọc tên khách, phòng, dịch vụ', () {
      final d = ContractDetailResult.fromJson({
        'id': 5,
        'tenantId': 't',
        'roomId': 3,
        'motelId': 1,
        'primaryResidentUserId': 'u',
        'rentPrice': 1000,
        'startDate': '2026-06-01',
        'endDate': '2027-06-01',
        'depositAmount': 1000,
        'depositStatus': 'UNPAID',
        'status': 'DRAFT',
        'residentUserIds': ['u', 'v'],
        'serviceItems': [
          {'serviceId': 1, 'quantity': 2}
        ],
        'appendicesCount': 2,
        'roomNumber': '101',
        'motelName': 'Nhà A',
        'primaryResidentFullName': 'Trần B',
        'primaryResidentPhone': '0909000111',
      });
      expect(d.roomNumber, '101');
      expect(d.primaryResidentFullName, 'Trần B');
      expect(d.residentUserIds.length, 2);
      expect(d.serviceItems.single['quantity'], 2);
    });

    test('phụ lục đọc appendixType và metadata JSON', () {
      final a = ContractAppendixResult.fromJson({
        'id': 1,
        'contractId': 5,
        'appendixType': 'RENEW',
        'effectiveDate': '2027-06-01',
        'metadata': '{"newEndDate":"2027-12-01","reason":"Khách ở thêm"}',
        'createdAt': '2026-06-01T10:00:00',
      });
      expect(a.type, 'RENEW');
      expect(a.newEndDate, '2027-12-01');
      expect(a.reason, 'Khách ở thêm');
      expect(a.isAmendment, isTrue);
      final dep = ContractAppendixResult.fromJson({
        'id': 2,
        'contractId': 5,
        'appendixType': 'DEPOSIT_COLLECTED',
        'metadata': '{"amount":3500000,"collectedDate":"2026-06-01","paymentMethod":"CASH"}',
      });
      expect(dep.isDepositRecord, isTrue);
      expect(dep.meta['paymentMethod'], 'CASH');
      final plain = ContractAppendixResult.fromJson({'appendixType': 'MANUAL_CLAUSE', 'metadata': 'không phải json'});
      expect(plain.clause, 'không phải json');
    });

    test('sắp hết hạn trong 30 ngày (BR64.4)', () {
      final today = DateTime(2026, 6, 1);
      expect(ContractRules.isExpiringSoon('ACTIVE', '2026-06-20', today: today), isTrue);
      expect(ContractRules.isExpiringSoon('ACTIVE', '2026-07-01', today: today), isTrue);
      expect(ContractRules.isExpiringSoon('ACTIVE', '2026-07-02', today: today), isFalse);
      expect(ContractRules.isExpiringSoon('CANCELED', '2026-06-20', today: today), isFalse);
      expect(ContractRules.isExpired('ACTIVE', '2026-05-31', today: today), isTrue);
    });

    test('nhãn trạng thái và định dạng tiền/ngày', () {
      expect(ContractRules.statusLabel('LIQUIDATED'), 'Đã thanh lý');
      expect(ContractRules.depositLabel('UNPAID'), 'Chờ thu');
      expect(Fmt.vnd(3500000), '3.500.000đ');
      expect(Fmt.vnd(-1200), '-1.200đ');
      expect(Fmt.date('2026-06-01'), '01/06/2026');
      expect(Fmt.parseMoney('3.500.000'), 3500000);
      expect(Fmt.parseMoney('abc'), isNull);
    });
  });

  group('UC67 – chặn hủy khi còn nợ', () {
    ContractInvoiceSummary inv(String status, double total, double paid) => ContractInvoiceSummary.fromJson({
          'id': 1,
          'invoiceType': 'MONTHLY',
          'status': status,
          'totalAmount': total,
          'paidAmount': paid,
          'balanceDeduction': 0,
          'remainingAmount': total - paid,
        });

    test('cho phép hủy khi chưa có hóa đơn', () {
      expect(ContractRules.cancelBlockReason('DRAFT', []), isNull);
      expect(ContractRules.cancelBlockReason('ACTIVE', [inv('VOID', 100, 0)]), isNull);
    });

    test('chặn khi còn công nợ hoặc đã có thanh toán', () {
      expect(ContractRules.cancelBlockReason('ACTIVE', [inv('PENDING', 100, 0)]), contains('công nợ'));
      expect(ContractRules.cancelBlockReason('ACTIVE', [inv('PAID', 100, 100)]), contains('Tất toán'));
      expect(ContractRules.cancelBlockReason('LIQUIDATED', []), isNotNull);
    });
  });

  group('UC80 – tất toán', () {
    test('công thức FinalBalance và chiều hoàn/thu thêm', () {
      final net = SettlementMath.finalBalance(
        deposit: 5000000,
        currentDebt: 1000000,
        proRatedRent: 1500000,
        finalUtilities: 500000,
        repairFees: 300000,
      );
      expect(net, 1700000);
      expect(SettlementMath.outcomeOf(net), SettlementOutcome.refund);
      expect(SettlementMath.outcomeOf(-10), SettlementOutcome.collectMore);
      expect(SettlementMath.outcomeOf(0), SettlementOutcome.even);
    });

    test('khấu trừ > 0 bắt buộc có ảnh bằng chứng', () {
      expect(SettlementMath.validateDamages([const DamageItem(itemName: 'Vỡ kính', penaltyFee: 200000)]),
          contains('ảnh bằng chứng'));
      expect(SettlementMath.validateDamages([const DamageItem(itemName: '', penaltyFee: 1, imageBase64: 'x')]),
          contains('tên'));
      expect(SettlementMath.validateDamages([const DamageItem(itemName: 'Ghế', penaltyFee: 0)]), isNull);
      expect(
          SettlementMath.validateDamages([const DamageItem(itemName: 'Ghế', penaltyFee: 100000, imageBase64: 'abc')]), isNull);
    });

    test('chỉ số cuối không nhỏ hơn kỳ trước', () {
      expect(SettlementMath.validateReading('điện', null), isNotNull);
      expect(SettlementMath.validateReading('điện', 90, previous: 100), contains('nhỏ hơn'));
      expect(SettlementMath.validateReading('nước', 120, previous: 100), isNull);
    });

    test('parse bảng kê, kết quả xác nhận và trạng thái', () {
      final calc = SettlementCalculation.fromJson({
        'contractId': 5,
        'deposit': 5000000,
        'currentDebt': 0,
        'proRatedRent': 1000000,
        'finalUtilities': 250000.5,
        'repairFees': 300000,
        'netAmount': 3449999.5,
      });
      expect(calc.totalCharges, closeTo(1550000.5, 0.001));
      expect(calc.outcome, SettlementOutcome.refund);

      final conf = SettlementConfirmation.fromJson({
        'contractId': 5,
        'contractStatus': 'PENDING_LIQUIDATION',
        'roomStatus': 'RENTED',
        'depositSnapshot': 1000000,
        'oldDebtDeducted': 0,
        'settlementDeducted': 1000000,
        'netAmount': -500000,
        'settlementInvoice': {'id': 99, 'status': 'PENDING', 'remainingAmount': 500000},
        'refundTransaction': null,
      });
      expect(conf.liquidated, isFalse);
      expect(conf.settlementInvoiceId, 99);
      expect(conf.settlementRemaining, 500000);
      expect(conf.refundAmount, isNull);

      final status = SettlementStatus.fromJson({
        'contractId': 5,
        'contractStatus': 'PENDING_LIQUIDATION',
        'settlementInvoiceId': 99,
        'settlementInvoiceStatus': 'PAID',
      });
      expect(status.readyToClose, isTrue);
      expect(status.awaitingExtraPayment, isFalse);
    });

    test('chỉ gửi hạng mục có phí > 0 kèm ảnh dạng imageUrl', () {
      final json = const DamageItem(itemName: ' Bàn ', penaltyFee: 100, imageBase64: 'b64').toJson();
      expect(json['itemName'], 'Bàn');
      expect(json['imageUrl'], 'b64');
    });
  });
}
