import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/maintenance_service.dart';

/// Widget dùng chung cho các màn bảo trì của Tenant / Manager / Technician.

String maintenanceTimeAgo(DateTime? time) {
  if (time == null) return '';
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return DateFormat('dd/MM/yyyy').format(time.toLocal());
}

class MaintenanceStatusChip extends StatelessWidget {
  final String status;
  const MaintenanceStatusChip({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'COMPLETED':
        color = AppColors.success;
        label = 'Đã Hoàn Thành';
        break;
      case 'PROCESSING':
        color = AppColors.warning;
        label = 'Đang Xử Lý';
        break;
      case 'CANCELLED':
        color = AppColors.danger;
        label = 'Đã Hủy';
        break;
      case 'ESCALATED':
        color = AppColors.danger;
        label = 'Cần Ưu Tiên';
        break;
      default:
        color = AppColors.info;
        label = 'Chờ Xử Lý';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

Color maintenancePriorityColor(String priority) {
  switch (priority) {
    case 'URGENT':
      return AppColors.danger;
    case 'HIGH':
      return AppColors.warning;
    case 'LOW':
      return AppColors.textSecondaryLight;
    default:
      return AppColors.primary;
  }
}

/// Thẻ phiếu bảo trì. [actions] là hàng nút thao tác theo từng role.
class MaintenanceTicketCard extends StatelessWidget {
  final MaintenanceTicketResult ticket;
  final List<Widget> actions;
  final bool showReporter;
  final VoidCallback? onTap;

  const MaintenanceTicketCard({
    Key? key,
    required this.ticket,
    this.actions = const [],
    this.showReporter = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pColor = maintenancePriorityColor(ticket.priority);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Phòng ${ticket.roomNumber} - ${ticket.categoryLabel}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaintenanceStatusChip(status: ticket.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(ticket.priorityLabel, style: TextStyle(fontSize: 10, color: pColor, fontWeight: FontWeight.bold)),
                  ),
                  if (ticket.beforeImages.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.photo_library_outlined, size: 13, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 3),
                    Text('${ticket.beforeImages.length}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ],
                  const Spacer(),
                  const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 3),
                  Text(maintenanceTimeAgo(ticket.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                ],
              ),
              if ((showReporter && (ticket.reporterName ?? '').isNotEmpty) || (ticket.technicianName ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                if (showReporter && (ticket.reporterName ?? '').isNotEmpty)
                  _metaLine(Icons.person_outline_rounded, 'Người báo: ${ticket.reporterName}'),
                if ((ticket.technicianName ?? '').isNotEmpty)
                  _metaLine(Icons.engineering_outlined, 'Thợ: ${ticket.technicianName}'),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _metaLine(IconData icon, String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(children: [
      Icon(icon, size: 14, color: AppColors.textSecondaryLight),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight), overflow: TextOverflow.ellipsis)),
    ]),
  );
}

/// Bottom sheet chi tiết phiếu (UC83): mô tả, ảnh trước/sau, vật tư đã dùng.
void showMaintenanceTicketDetail(BuildContext context, MaintenanceTicketResult t) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Phòng ${t.roomNumber} - ${t.categoryLabel}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              MaintenanceStatusChip(status: t.status),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('Mô tả', t.description),
          _detailRow('Ưu tiên', t.priorityLabel),
          _detailRow('Người báo', t.reporterName ?? '—'),
          _detailRow('Thợ phụ trách', t.technicianName ?? 'Chưa giao thợ'),
          _detailRow('Báo lúc', t.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(t.createdAt!.toLocal()) : '—'),
          if (t.completedAt != null)
            _detailRow('Hoàn thành', DateFormat('dd/MM/yyyy HH:mm').format(t.completedAt!.toLocal())),
          if (t.beforeImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Ảnh hiện trạng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _imageStrip(context, t.beforeImages),
          ],
          if (t.details.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Kết quả xử lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...t.details.map((d) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if ((d.deviceName ?? '').isNotEmpty)
                        Text('Vật tư: ${d.deviceName} x${d.quantityUsed}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if ((d.note ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Ghi chú: ${d.note}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        ),
                      if (d.afterImages.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _imageStrip(context, d.afterImages),
                      ],
                    ]),
                  ),
                )),
          ],
        ],
      ),
    ),
  );
}

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
      ],
    ),
  );
}

Widget _imageStrip(BuildContext context, List<String> urls) {
  return SizedBox(
    height: 90,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: urls.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(urls[i], fit: BoxFit.contain)),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            urls[i],
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              color: AppColors.borderLight,
              child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Chọn tối đa [maxCount] ảnh (chụp hoặc thư viện) để đính kèm phiếu.
class MaintenancePhotoPicker extends StatefulWidget {
  final List<XFile> files;
  final ValueChanged<List<XFile>> onChanged;
  final int maxCount;

  const MaintenancePhotoPicker({Key? key, required this.files, required this.onChanged, this.maxCount = 5})
      : super(key: key);

  @override
  State<MaintenancePhotoPicker> createState() => _MaintenancePhotoPickerState();
}

class _MaintenancePhotoPickerState extends State<MaintenancePhotoPicker> {
  final _picker = ImagePicker();
  final Map<String, Future<dynamic>> _bytes = {};

  Future<void> _pick(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final picked = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1600);
        if (picked.isEmpty) return;
        widget.onChanged([...widget.files, ...picked].take(widget.maxCount).toList());
      } else {
        final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 1600);
        if (picked == null) return;
        widget.onChanged([...widget.files, picked].take(widget.maxCount).toList());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể mở camera/thư viện ảnh')));
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: AppColors.primary),
            title: const Text('Chụp ảnh'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
            title: const Text('Chọn từ thư viện'),
            onTap: () {
              Navigator.pop(ctx);
              _pick(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...widget.files.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder<dynamic>(
                      future: _bytes.putIfAbsent(f.path + f.name, () => f.readAsBytes()),
                      builder: (_, snap) => snap.hasData
                          ? Image.memory(snap.data, width: 72, height: 72, fit: BoxFit.cover)
                          : Container(width: 72, height: 72, color: AppColors.borderLight),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => widget.onChanged(widget.files.where((x) => x != f).toList()),
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ]),
              )),
          if (widget.files.length < widget.maxCount)
            GestureDetector(
              onTap: _showSourceSheet,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Dropdown theo kiểu form có sẵn của app (nền #F8FAFC, viền #E2E8F0, bo 14).
InputDecoration maintenanceInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
  );
}

/// Banner lỗi hiển thị ngay trong bottom sheet (SnackBar bị sheet che nên người dùng không thấy).
class MaintenanceErrorBanner extends StatelessWidget {
  final String? message;
  const MaintenanceErrorBanner(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(message!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
    );
  }
}
