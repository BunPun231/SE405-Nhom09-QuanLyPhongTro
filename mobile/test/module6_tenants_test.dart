import 'package:flutter_test/flutter_test.dart';
import 'package:room_rental_mobile/core/services/resident_service.dart';
import 'package:room_rental_mobile/presentation/screens/manager/tenants/tenant_ui.dart';

void main() {
  group('Module VI – parse JSON', () {
    test('ResidentResult đọc đủ trường mới (UC49)', () {
      final r = ResidentResult.fromJson({
        'userId': 'u-1',
        'fullName': 'Nguyễn Văn A',
        'phone': '0901234567',
        'email': '',
        'status': 'ACTIVE',
        'idCardNumber': '079090000001',
        'avatarUrl': 'data:image/jpeg;base64,AAAA',
        'dateOfBirth': '1990-05-20',
        'gender': 'MALE',
        'notes': 'Đi làm ca đêm',
      });
      expect(r.userId, 'u-1');
      expect(r.email, isNull, reason: 'chuỗi rỗng coi như không có');
      expect(r.active, isTrue);
      expect(r.dateOfBirth, DateTime(1990, 5, 20));
      expect(r.gender, 'MALE');
      expect(r.notes, 'Đi làm ca đêm');
    });

    test('parseApiDate nhận chuỗi ISO và mảng Jackson', () {
      expect(parseApiDate('2026-03-01'), DateTime(2026, 3, 1));
      expect(parseApiDate([2026, 3, 1]), DateTime(2026, 3, 1));
      expect(parseApiDate(null), isNull);
      expect(parseApiDate(''), isNull);
    });

    test('ResidentPage dùng khóa page/totalPages của backend (UC50)', () {
      final page = ResidentPage.fromJson({
        'content': [
          {
            'userId': 'u-1',
            'fullName': 'Trần B',
            'phone': '0912345678',
            'accountStatus': 'ACTIVE',
            'contractId': 12,
            'contractStatus': 'ACTIVE',
            'roomNumber': '101',
            'motelName': 'Khu A',
            'residencyStatus': 'LIVING',
            'debtAmount': 1500000.5,
            'unpaidInvoiceCount': 2,
          }
        ],
        'page': 0,
        'size': 20,
        'totalElements': 45,
        'totalPages': 3,
      }, ResidentSummary.fromJson);
      expect(page.content, hasLength(1));
      expect(page.hasMore, isTrue);
      final s = page.content.first;
      expect(s.contractId, 12);
      expect(s.hasDebt, isTrue);
      expect(s.debtAmount, closeTo(1500000.5, 0.001));
      expect(s.roomNumber, '101');

      final last = ResidentPage.fromJson(
          {'content': [], 'page': 2, 'totalPages': 3, 'totalElements': 45},
          ResidentSummary.fromJson);
      expect(last.hasMore, isFalse);
    });

    test('ResidentHistoryItem đọc tóm tắt lần ở và tất toán (UC52)', () {
      final h = ResidentHistoryItem.fromJson({
        'userId': 'u-9',
        'fullName': 'Lê C',
        'phone': '0987654321',
        'accountStatus': 'INACTIVE',
        'contractId': 7,
        'contractStatus': 'LIQUIDATED',
        'roomNumber': '202',
        'checkInDate': '2025-01-01',
        'checkOutDate': '2026-02-15',
        'stayDays': 410,
        'depositAmount': 3000000,
        'depositStatus': 'REFUNDED',
        'settlementTotal': 500000,
        'settlementPaid': 500000,
        'settlementStatus': 'PAID',
        'remainingDebt': 0,
        'endReason': 'Chuyển công tác',
      });
      expect(h.checkOutDate, DateTime(2026, 2, 15));
      expect(h.stayDays, 410);
      expect(h.settlementTotal, 500000);
      expect(h.remainingDebt, 0);
    });

    test('ResidentOverview: hợp đồng hiện tại, khả năng vô hiệu hóa, nhật ký (UC51/UC54)', () {
      final o = ResidentOverview.fromJson({
        'profile': {'userId': 'u-1', 'fullName': 'A', 'phone': '0901234567', 'status': 'ACTIVE'},
        'residencyStatus': 'LIVING',
        'totalDebt': 200000,
        'unpaidInvoiceCount': 1,
        'canDeactivate': false,
        'deactivateBlockReason': 'Khách còn hợp đồng #5 chưa thanh lý.',
        'contracts': [
          {'id': 3, 'status': 'LIQUIDATED', 'rentPrice': 2000000, 'depositAmount': 0, 'primary': true},
          {'id': 5, 'status': 'ACTIVE', 'roomNumber': '101', 'rentPrice': 2500000, 'depositAmount': 2500000, 'primary': false},
        ],
        'invoices': [
          {'id': 1, 'contractId': 5, 'status': 'PARTIAL', 'totalAmount': 300000, 'paidAmount': 100000, 'remainingAmount': 200000, 'billingMonth': '2026-10-01'},
        ],
        'maintenanceRequests': [
          {'id': 4, 'category': 'ELECTRIC', 'description': 'Hỏng ổ cắm', 'status': 'OPEN', 'createdAt': '2026-10-02T08:30:00'},
        ],
        'activities': [
          {'action': 'UPDATE_RESIDENT', 'oldValue': '0901', 'newValue': '0902', 'metadata': '{"field":"phone"}', 'timestamp': '2026-10-03T10:00:00Z'},
        ],
      });
      expect(o.currentContract?.id, 5);
      expect(o.canDeactivate, isFalse);
      expect(o.deactivateBlockReason, contains('#5'));
      expect(o.invoices.single.unpaid, isTrue);
      expect(o.maintenanceRequests.single.createdAt, isNotNull);
      expect(o.activities.single.field, 'phone');
    });

    test('IdCardOcrResult chuẩn hóa số CCCD và ngày sinh', () {
      final r = IdCardOcrResult.fromJson(
          {'idNumber': '079 090 000 001', 'fullName': ' Phạm D ', 'dateOfBirth': '20/05/1990'});
      expect(r.idCardNumber, '079090000001');
      expect(r.fullName, 'Phạm D');
      expect(r.dateOfBirth, DateTime(1990, 5, 20));
      expect(IdCardOcrResult.fromJson({'idNumber': '', 'fullName': ''}).isEmpty, isTrue);
    });
  });

  group('Module VI – body gửi API', () {
    test('buildCreateBody bỏ trường rỗng, định dạng ngày, kèm contractId', () {
      final body = ResidentService.buildCreateBody(
        fullName: ' Nguyễn Văn A ',
        phone: '0901 234 567',
        idCardNumber: '079090000001',
        email: '  ',
        dateOfBirth: DateTime(1990, 1, 5),
        gender: 'FEMALE',
        notes: '',
        contractId: 9,
      );
      expect(body['fullName'], 'Nguyễn Văn A');
      expect(body['phone'], '0901234567');
      expect(body.containsKey('email'), isFalse);
      expect(body.containsKey('notes'), isFalse);
      expect(body['dateOfBirth'], '1990-01-05');
      expect(body['gender'], 'FEMALE');
      expect(body['contractId'], 9);
    });

    test('buildUpdateBody chỉ gửi trường đổi và không bao giờ gửi họ tên/CCCD (UC53)', () {
      final original = ResidentResult(
        userId: 'u-1',
        fullName: 'A',
        phone: '0901234567',
        email: 'a@x.vn',
        idCardNumber: '079090000001',
        status: 'ACTIVE',
        notes: 'cũ',
      );
      final unchanged = ResidentService.buildUpdateBody(
          original: original, phone: '0901234567', email: 'a@x.vn', notes: 'cũ');
      expect(unchanged, isEmpty);

      final changed = ResidentService.buildUpdateBody(
          original: original, phone: '0912345678', email: '', notes: 'mới');
      expect(changed, {'phone': '0912345678', 'email': '', 'notes': 'mới'});
      expect(changed.containsKey('fullName'), isFalse);
      expect(changed.containsKey('idCardNumber'), isFalse);
    });
  });

  group('Module VI – kiểm tra dữ liệu', () {
    test('Số điện thoại Việt Nam', () {
      expect(ResidentValidators.phone('0901234567'), isNull);
      expect(ResidentValidators.phone('84901234567'), isNull);
      expect(ResidentValidators.phone('0123456789'), isNotNull);
      expect(ResidentValidators.phone(''), isNotNull);
    });

    test('CCCD đúng 12 số, email tùy chọn, ngày sinh không ở tương lai', () {
      expect(ResidentValidators.idCard('079090000001'), isNull);
      expect(ResidentValidators.idCard('07909000000'), isNotNull);
      expect(ResidentValidators.idCard('07909000000a'), isNotNull);
      expect(ResidentValidators.email(''), isNull);
      expect(ResidentValidators.email('abc'), isNotNull);
      expect(ResidentValidators.fullName(' '), isNotNull);
      final now = DateTime(2026, 11, 2);
      expect(ResidentValidators.dateOfBirth(DateTime(2027, 1, 1), now: now), isNotNull);
      expect(ResidentValidators.dateOfBirth(DateTime(1990, 1, 1), now: now), isNull);
    });
  });

  group('Module VI – nhãn và định dạng', () {
    test('Nhãn trạng thái tiếng Việt', () {
      expect(TenantLabels.residency('LIVING'), 'Đang ở');
      expect(TenantLabels.residency('FORMER'), 'Đã trả phòng');
      expect(TenantLabels.contract('LIQUIDATED'), 'HĐ đã thanh lý');
      expect(TenantLabels.contract(null), 'Chưa có hợp đồng');
      expect(TenantLabels.invoice('PARTIAL'), 'Thu một phần');
      expect(TenantLabels.contractTone('ACTIVE'), TenantTone.green);
      expect(TenantLabels.invoiceTone('PENDING'), TenantTone.red);
    });

    test('Tiền, ngày, thời gian ở', () {
      expect(TenantFormat.money(1500000), '1.500.000 đ');
      expect(TenantFormat.money(0), '0 đ');
      expect(TenantFormat.date(DateTime(2026, 3, 5)), '05/03/2026');
      expect(TenantFormat.duration(400), '1 năm 1 tháng');
      expect(TenantFormat.duration(45), '1 tháng 15 ngày');
      expect(TenantFormat.duration(0), 'Dưới 1 ngày');
      expect(TenantFormat.initials('Nguyễn Văn An'), 'A');
    });

    test('Ảnh data URI giải mã được, chuỗi khác trả null', () {
      expect(decodeDataImage('data:image/jpeg;base64,AQID'), [1, 2, 3]);
      expect(decodeDataImage('https://x/y.jpg'), isNull);
      expect(toDataImageUri('AQID'), 'data:image/jpeg;base64,AQID');
    });
  });
}
