import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/invoice_service.dart';
import '../../../../core/services/motel_service.dart';
import 'invoice_widgets.dart';

/// Kết quả đóng sheet tạo hóa đơn.
class InvoiceGenerateOutcome {
  final bool ran;
  final int? motelId;
  final DateTime? viewMonth; // != null khi Quản lý muốn xem ngay hóa đơn kỳ này
  const InvoiceGenerateOutcome({required this.ran, this.motelId, this.viewMonth});
}

/// UC73: Tạo hóa đơn tháng cho một khu trọ.
Future<InvoiceGenerateOutcome?> showInvoiceGenerateSheet(
  BuildContext context, {
  required List<MotelResult> motels,
  int? initialMotelId,
}) {
  return showModalBottomSheet<InvoiceGenerateOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GenerateSheet(motels: motels, initialMotelId: initialMotelId),
  );
}

class _GenerateSheet extends StatefulWidget {
  final List<MotelResult> motels;
  final int? initialMotelId;
  const _GenerateSheet({required this.motels, this.initialMotelId});

  @override
  State<_GenerateSheet> createState() => _GenerateSheetState();
}

class _GenerateSheetState extends State<_GenerateSheet> {
  int? _motelId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _running = false;
  String? _error;
  InvoiceGenerationResult? _result;

  @override
  void initState() {
    super.initState();
    _motelId = widget.initialMotelId ?? (widget.motels.length == 1 ? widget.motels.first.id : null);
  }

  Future<void> _run() async {
    if (_motelId == null) {
      setState(() => _error = 'Vui lòng chọn khu trọ.');
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    try {
      final res = await InvoiceService.generate(motelId: _motelId!, billingMonth: billingMonthKey(_month));
      if (mounted) {
        setState(() {
          _result = res;
          _running = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = cleanError(e);
        });
      }
    }
  }

  void _close({bool view = false}) {
    Navigator.pop(
      context,
      InvoiceGenerateOutcome(ran: _result != null, motelId: _motelId, viewMonth: view ? _month : null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHeader(
            icon: Icons.receipt_long_rounded,
            title: 'Tạo hóa đơn tháng',
            subtitle: 'Tiền phòng, điện nước (cả giá bậc thang) và dịch vụ',
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: _result == null ? _form() : _resultView(_result!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Khu trọ'),
        if (widget.motels.isEmpty)
          const Text('Chưa có khu trọ nào.', style: TextStyle(fontSize: 13, color: InvoiceTones.muted))
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: InvoiceTones.hairline),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _motelId,
                hint: const Text('Chọn khu trọ', style: TextStyle(fontSize: 14)),
                style: const TextStyle(fontSize: 14, color: InvoiceTones.heading),
                items: widget.motels
                    .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _motelId = v;
                  _error = null;
                }),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const SectionLabel('Kỳ hóa đơn'),
        OutlinedButton.icon(
          style: InvoiceButtonStyles.outlined(),
          onPressed: () async {
            final picked = await pickBillingMonth(context, initial: _month);
            if (picked != null) setState(() => _month = picked);
          },
          icon: const Icon(Icons.calendar_month_rounded),
          label: Text(formatBillingMonth(billingMonthKey(_month))),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: InvoiceTones.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: InvoiceTones.hairline),
          ),
          child: const Text(
            'Phòng chưa có chỉ số điện nước đã duyệt (APPROVED) sẽ được bỏ qua. '
            'Phòng đã có hóa đơn kỳ này không bị tạo trùng, nên có thể chạy lại an toàn. '
            'Khách thuê nhận thông báo khi hóa đơn được tạo.',
            style: TextStyle(fontSize: 13, color: InvoiceTones.heading, height: 1.4),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(fontSize: 13, color: InvoiceTones.dangerText)),
        ],
        const SizedBox(height: 20),
        ElevatedButton.icon(
          style: InvoiceButtonStyles.primary(),
          onPressed: _running || widget.motels.isEmpty ? null : _run,
          icon: _running
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.flash_on_rounded),
          label: Text(_running ? 'Đang tạo hóa đơn...' : 'Tạo hóa đơn'),
        ),
      ],
    );
  }

  Widget _resultView(InvoiceGenerationResult r) {
    final missing = r.missingReadingRooms;
    final existing = r.alreadyInvoicedRooms;
    final errors = r.errorRooms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (r.createdCount > 0 ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                r.createdCount > 0 ? Icons.check_circle_rounded : Icons.info_rounded,
                color: r.createdCount > 0 ? InvoiceTones.paidText : InvoiceTones.pendingText,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đã tạo ${r.createdCount} hóa đơn',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: InvoiceTones.ink),
                    ),
                    Text(
                      '${formatBillingMonth(billingMonthKey(_month))} · Tổng ${formatVnd(r.createdTotal)}',
                      style: const TextStyle(fontSize: 13, color: InvoiceTones.heading),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _skipGroup(
          icon: Icons.speed_rounded,
          color: InvoiceTones.pendingText,
          title: 'Bỏ qua ${missing.length} phòng chưa có chỉ số APPROVED',
          rooms: missing,
          hint: 'Duyệt chỉ số điện nước cho các phòng này rồi chạy lại.',
        ),
        _skipGroup(
          icon: Icons.content_copy_rounded,
          color: InvoiceTones.voidText,
          title: '${existing.length} phòng đã có hóa đơn kỳ này (không tạo trùng)',
          rooms: existing,
        ),
        _skipGroup(
          icon: Icons.error_outline_rounded,
          color: InvoiceTones.dangerText,
          title: '${errors.length} phòng gặp lỗi',
          rooms: errors,
          showReason: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: InvoiceButtonStyles.outlined(),
                onPressed: () => _close(),
                child: const Text('Đóng'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: InvoiceButtonStyles.primary(),
                onPressed: () => _close(view: true),
                child: const Text('Xem hóa đơn kỳ này'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _skipGroup({
    required IconData icon,
    required Color color,
    required String title,
    required List<SkippedInvoiceRoom> rooms,
    String? hint,
    bool showReason = false,
  }) {
    if (rooms.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: InvoiceTones.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showReason
                ? rooms.map((r) => '${r.roomLabel}: ${r.reason}').join('\n')
                : rooms.map((r) => r.roomLabel).join(', '),
            style: const TextStyle(fontSize: 13, color: InvoiceTones.heading, height: 1.4),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(fontSize: 12, color: InvoiceTones.muted)),
          ],
        ],
      ),
    );
  }
}
