import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/meter_reading_service.dart';
import '../../tenant/meter/meter_widgets.dart';

/// Một ô phòng × dịch vụ của kỳ đang xem.
class MeterReviewEntry {
  final int roomId;
  final String roomLabel;
  final int serviceId;
  final String serviceName;
  final String? unit;
  final MeterReading? reading;

  /// Chỉ số cũ suy ra từ kỳ đã duyệt gần nhất (khi chưa có bản ghi kỳ này).
  final double? knownOldReading;

  /// Trung bình tiêu thụ 3 kỳ đã duyệt gần nhất (BR70.5).
  final double? average;

  MeterReviewEntry({
    required this.roomId,
    required this.roomLabel,
    required this.serviceId,
    required this.serviceName,
    this.unit,
    this.reading,
    this.knownOldReading,
    this.average,
  });

  /// Tiêu thụ vượt 130% trung bình (BR70.7) → không được duyệt nhanh.
  bool get isHighConsumption => MeterRules.isHighConsumption(reading?.consumption, average);

  /// Khóa trạng thái để lọc: PENDING / APPROVED / REJECTED / MISSING.
  String get statusKey {
    final r = reading;
    if (r == null) return 'MISSING';
    if (r.isPending) return MeterStatus.pending;
    return r.status;
  }
}

/// Thẻ đối soát: ảnh đồng hồ và các con số đặt cạnh nhau (US70.2).
class MeterReviewCard extends StatelessWidget {
  final MeterReviewEntry entry;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRecord;

  const MeterReviewCard({
    super.key,
    required this.entry,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final r = entry.reading;
    final high = entry.isHighConsumption;
    final unit = (entry.unit == null || entry.unit!.isEmpty) ? '' : ' ${entry.unit}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: high && r != null && r.isPending ? AppColors.danger.withValues(alpha: 0.4) : MeterTone.mist),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MeterServiceIcon(entry.serviceName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Phòng ${entry.roomLabel}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MeterTone.heading)),
                    Text(entry.serviceName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                  ],
                ),
              ),
              MeterStatusBadge(r?.status),
            ],
          ),
          const SizedBox(height: 12),
          if (r == null)
            Row(
              children: [
                Expanded(
                  child: MeterNumber(
                    label: 'Chỉ số cũ',
                    value: MeterRules.formatReading(entry.knownOldReading),
                  ),
                ),
                const Expanded(
                  child: MeterNumber(label: 'Chỉ số mới', value: 'Chưa ghi', color: AppColors.textSecondaryLight),
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MeterImageThumb(url: r.imageUrl, size: 112),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MeterNumber(label: 'Chỉ số mới', value: MeterRules.formatReading(r.newReading), fontSize: 22),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: MeterNumber(
                                label: 'Chỉ số cũ', value: MeterRules.formatReading(r.oldReading), fontSize: 15),
                          ),
                          Expanded(
                            child: MeterNumber(
                              label: 'Tiêu thụ',
                              value: '${MeterRules.formatReading(r.consumption)}$unit',
                              fontSize: 15,
                              color: high ? MeterTone.dangerText : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.average == null
                            ? 'Chưa có dữ liệu 3 tháng trước'
                            : 'TB 3 tháng: ${MeterRules.formatReading(entry.average!.roundToDouble())}$unit',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                      ),
                      if (r.ocrConfidence != null)
                        Text('AI tin cậy ${r.ocrConfidence!.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          if (r != null && high) ...[
            const SizedBox(height: 12),
            MeterNotice.danger('Tiêu thụ vượt 130% trung bình 3 tháng. Hãy đối chiếu ảnh kỹ trước khi duyệt.'),
          ],
          if (r != null && r.isRejected && r.rejectReason != null) ...[
            const SizedBox(height: 12),
            MeterNotice.danger('Lý do từ chối: ${r.rejectReason}'),
          ],
          if (r == null || r.isPending || r.isRejected) ...[
            const SizedBox(height: 12),
            _actions(r),
          ],
        ],
      ),
    );
  }

  Widget _actions(MeterReading? r) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    if (r == null || r.isRejected) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onRecord,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(r == null ? 'Tự chốt số' : 'Tự chốt lại số'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.borderLight),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            shape: shape,
          ),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onReject,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Từ chối'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              foregroundColor: MeterTone.dangerText,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.4)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              shape: shape,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onApprove,
            icon: busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Duyệt'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: MeterTone.confirm,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              shape: shape,
            ),
          ),
        ),
      ],
    );
  }
}

/// Hộp thoại nhập lý do từ chối (bắt buộc). Trả null nếu hủy.
Future<String?> askMeterRejectReason(BuildContext context, MeterReviewEntry entry) {
  return showDialog<String>(
    context: context,
    builder: (_) => _RejectDialog(entry: entry),
  );
}

class _RejectDialog extends StatefulWidget {
  final MeterReviewEntry entry;
  const _RejectDialog({required this.entry});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  bool _tried = false;

  static const _quick = [
    'Ảnh mờ, không đọc được số',
    'Số khai báo không khớp với ảnh',
    'Ảnh không phải đồng hồ của phòng',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      setState(() => _tried = true);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final showError = _tried && _ctrl.text.trim().isEmpty;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Từ chối chỉ số phòng ${widget.entry.roomLabel}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Khách thuê sẽ thấy lý do này để chụp và gửi lại.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quick
                  .map((q) => ActionChip(
                        label: Text(q, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        onPressed: () => setState(() {
                          _ctrl.text = q;
                          _ctrl.selection = TextSelection.collapsed(offset: q.length);
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 2,
              onChanged: (_) {
                if (_tried) setState(() {});
              },
              decoration: InputDecoration(
                labelText: 'Lý do từ chối *',
                errorText: showError ? 'Vui lòng nhập lý do từ chối' : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: MeterTone.dangerText, minimumSize: const Size(0, 44)),
          child: const Text('Từ chối'),
        ),
      ],
    );
  }
}
