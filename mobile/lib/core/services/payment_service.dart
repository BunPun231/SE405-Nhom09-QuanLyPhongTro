import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';
import 'motel_service.dart';

// ─── Module IX – Thanh toán & lịch sử giao dịch (UC78, UC79) ─────────────────

double _num(dynamic v) => v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0 : 0);
int? _intOrNull(dynamic v) => v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

String _vnd(num v) {
  final r = v.round();
  final s = r.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return '${r < 0 ? '-' : ''}$sđ';
}

/// Phương thức thanh toán backend: VIETQR | CASH | BANK_TRANSFER.
String paymentMethodLabel(String? method) {
  switch (method) {
    case 'VIETQR':
      return 'VietQR';
    case 'CASH':
      return 'Tiền mặt';
    case 'BANK_TRANSFER':
      return 'Chuyển khoản';
    default:
      return method ?? '-';
  }
}

/// Trạng thái giao dịch (BR79.5).
String transactionStatusLabel(String? status) {
  switch (status) {
    case 'SUCCESS':
      return 'Thành công';
    case 'FAILED':
      return 'Thất bại';
    case 'PENDING_RECONCILE':
      return 'Chờ đối soát';
    default:
      return status ?? '-';
  }
}

class TransactionResult {
  final int id;
  final int? invoiceId;
  final double amount;
  final double overpaidAmount;
  final double creditBalanceSnapshot;
  final String? transactionRef;
  final String? paymentMethod;
  final String? bankCode;
  final String status;
  final String? paidAt;

  TransactionResult({
    required this.id,
    this.invoiceId,
    required this.amount,
    this.overpaidAmount = 0,
    this.creditBalanceSnapshot = 0,
    this.transactionRef,
    this.paymentMethod,
    this.bankCode,
    required this.status,
    this.paidAt,
  });

  /// Giao dịch chưa gán được hóa đơn (BR78.7 / BR79.7).
  bool get needsReconcile => status == 'PENDING_RECONCILE' || invoiceId == null || invoiceId == 0;
  bool get isOverpaid => overpaidAmount > 0;
  DateTime? get paidAtDate => paidAt == null ? null : DateTime.tryParse(paidAt!)?.toLocal();

  factory TransactionResult.fromJson(Map<String, dynamic> json) {
    final invoiceId = _intOrNull(json['invoiceId']);
    return TransactionResult(
      id: _intOrNull(json['id']) ?? 0,
      invoiceId: invoiceId == 0 ? null : invoiceId,
      amount: _num(json['amount']),
      overpaidAmount: _num(json['overpaidAmount']),
      creditBalanceSnapshot: _num(json['creditBalanceSnapshot']),
      transactionRef: json['transactionRef']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      bankCode: json['bankCode']?.toString(),
      status: json['status']?.toString() ?? 'SUCCESS',
      paidAt: json['paidAt']?.toString(),
    );
  }
}

/// Lọc lịch sử giao dịch (BR79.8): tìm theo mã tham chiếu / mã hóa đơn / số tiền, phương thức, trạng thái, khoảng ngày.
List<TransactionResult> filterTransactions(
  List<TransactionResult> items, {
  String query = '',
  String? method,
  String? status,
  DateTime? from,
  DateTime? to,
}) {
  final q = query.trim().toLowerCase().replaceFirst('#', '');
  final qDigits = q.replaceAll(RegExp(r'[^0-9]'), '');
  return items.where((t) {
    if (method != null && method.isNotEmpty && t.paymentMethod != method) return false;
    if (status != null && status.isNotEmpty && t.status != status) return false;
    final date = t.paidAtDate;
    if (from != null && (date == null || date.isBefore(DateTime(from.year, from.month, from.day)))) return false;
    if (to != null && (date == null || !date.isBefore(DateTime(to.year, to.month, to.day).add(const Duration(days: 1))))) {
      return false;
    }
    if (q.isEmpty) return true;
    return (t.transactionRef ?? '').toLowerCase().contains(q) ||
        (t.bankCode ?? '').toLowerCase().contains(q) ||
        (t.invoiceId != null && '${t.invoiceId}' == q) ||
        (qDigits.isNotEmpty && qDigits.length >= 3 && t.amount.round().toString().contains(qDigits));
  }).toList();
}

String _csvCell(String v) {
  final needsQuote = v.contains(',') || v.contains('"') || v.contains('\n');
  final escaped = v.replaceAll('"', '""');
  return needsQuote ? '"$escaped"' : escaped;
}

/// CSV lịch sử giao dịch (mở được bằng Excel nhờ BOM UTF-8).
String buildTransactionsCsv(List<TransactionResult> items) {
  final sb = StringBuffer('﻿');
  sb.writeln('Ngày giờ,Số tiền (VND),Phương thức,Mã tham chiếu,Ngân hàng,Mã hóa đơn,Trạng thái,Tiền thừa (VND)');
  for (final t in items) {
    final d = t.paidAtDate;
    String two(int n) => n.toString().padLeft(2, '0');
    final date = d == null ? '' : '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    sb.writeln([
      date,
      t.amount.round().toString(),
      paymentMethodLabel(t.paymentMethod),
      t.transactionRef ?? '',
      t.bankCode ?? '',
      t.invoiceId != null ? '#${t.invoiceId}' : '',
      transactionStatusLabel(t.status),
      t.overpaidAmount.round().toString(),
    ].map(_csvCell).join(','));
  }
  return sb.toString();
}

/// Mô tả ngắn kết quả sau khi ghi nhận [amount] cho hóa đơn còn nợ [remaining] (BR78.4–78.6).
String describePaymentOutcome(double amount, double remaining) {
  if (amount <= 0) return 'Nhập số tiền lớn hơn 0.';
  if (amount < remaining) return 'Hóa đơn chuyển sang Thanh toán một phần, còn nợ ${_vnd(remaining - amount)}.';
  if (amount == remaining) return 'Hóa đơn chuyển sang Đã thanh toán.';
  return 'Hóa đơn Đã thanh toán, tiền thừa ${_vnd(amount - remaining)} được cộng vào số dư của khách.';
}

class PaymentService {
  /// UC78: Ghi nhận thanh toán thủ công — POST /api/v1/payments/manual
  static Future<void> pay({required int invoiceId, required double amount, required String paymentMethod}) async {
    await recordManual(invoiceId: invoiceId, amount: amount, paymentMethod: paymentMethod);
  }

  /// UC78: như [pay] nhưng trả về giao dịch đã tạo.
  static Future<TransactionResult?> recordManual({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
  }) async {
    final data = await ApiClient.post('/api/v1/payments/manual', body: {
      'invoiceId': invoiceId,
      'amount': amount.round(),
      'paymentMethod': paymentMethod,
    });
    return data is Map<String, dynamic> ? TransactionResult.fromJson(data) : null;
  }

  /// UC79 / BR79.7: Gán giao dịch chờ đối soát cho hóa đơn — POST /api/v1/payments/reconcile
  static Future<TransactionResult?> reconcile({required int transactionId, required int invoiceId}) async {
    final data = await ApiClient.post('/api/v1/payments/reconcile', body: {
      'transactionId': transactionId,
      'invoiceId': invoiceId,
    });
    return data is Map<String, dynamic> ? TransactionResult.fromJson(data) : null;
  }

  /// UC79: Lịch sử giao dịch — GET /api/v1/payments/transactions (mới nhất trước).
  /// Khách thuê chỉ nhận giao dịch của mình; [invoiceId] lọc theo một hóa đơn.
  static Future<PageResponse<TransactionResult>> transactions({int? invoiceId, int page = 0, int size = 50}) async {
    final data = await ApiClient.get('/api/v1/payments/transactions', params: {
      if (invoiceId != null) 'invoiceId': invoiceId,
      'page': page,
      'size': size,
    });
    return PageResponse.fromJson(data as Map<String, dynamic>, TransactionResult.fromJson);
  }

  /// Xuất CSV vào thư mục tài liệu của app rồi mở bằng ứng dụng phù hợp. Trả về đường dẫn file.
  static Future<String> exportCsv(List<TransactionResult> items) async {
    final dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name = 'lich_su_giao_dich_${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}.csv';
    final file = File('${dir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(utf8.encode(buildTransactionsCsv(items)));
    await OpenFilex.open(file.path, type: 'text/csv');
    return file.path;
  }
}
