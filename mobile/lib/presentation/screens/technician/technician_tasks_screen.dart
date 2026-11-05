import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/maintenance_service.dart';
import '../../widgets/maintenance_widgets.dart';

class TechnicianTasksScreen extends StatefulWidget {
  const TechnicianTasksScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianTasksScreen> createState() => _TechnicianTasksScreenState();
}

class _TechnicianTasksScreenState extends State<TechnicianTasksScreen> {
  List<MaintenanceTicketResult> _tasks = [];
  String _filter = 'TODO'; // TODO | DONE | ALL
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final res = await MaintenanceService.listMyTasks(size: 100);
      if (!mounted) return;
      setState(() {
        _tasks = res.content;
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  bool _isTodo(MaintenanceTicketResult t) => t.isOpen || t.isProcessing || t.status == 'ESCALATED';

  List<MaintenanceTicketResult> get _visible {
    switch (_filter) {
      case 'TODO':
        return _tasks.where(_isTodo).toList();
      case 'DONE':
        return _tasks.where((t) => t.isCompleted).toList();
      default:
        return _tasks;
    }
  }

  Future<void> _showCompleteSheet(MaintenanceTicketResult t) async {
    // Vật tư có thể dùng: thiết bị còn trong kho của khu trọ chứa phòng này.
    List<DeviceResult> devices = [];
    if (t.motelId != null) {
      try {
        final res = await DeviceService.list(t.motelId!);
        devices = res.content.where((d) => d.availableQuantity > 0).toList();
      } catch (_) {
        devices = [];
      }
    }
    if (!mounted) return;

    final noteController = TextEditingController();
    int? deviceId;
    var quantity = 1;
    var photos = <XFile>[];
    var submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, setSheet) {
        DeviceResult? selected;
        for (final d in devices) {
          if (d.id == deviceId) selected = d;
        }
        final maxQty = selected?.availableQuantity ?? 1;
        return Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Xác Nhận Hoàn Thành', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Phòng ${t.roomNumber} - ${t.categoryLabel}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Ghi chú xử lý', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                if (devices.isNotEmpty) ...[
                  DropdownButtonFormField<int?>(
                    value: deviceId,
                    isExpanded: true,
                    decoration: maintenanceInputDecoration('Vật tư đã dùng (nếu có)'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Không dùng vật tư')),
                      ...devices.map((d) => DropdownMenuItem<int?>(
                            value: d.id,
                            child: Text('${d.name} (còn ${d.availableQuantity})', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setSheet(() {
                      deviceId = v;
                      quantity = 1;
                    }),
                  ),
                  if (deviceId != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      const Text('Số lượng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: quantity > 1 ? () => setSheet(() => quantity--) : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: quantity < maxQty ? () => setSheet(() => quantity++) : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 12),
                ],
                const Text('Ảnh sau khi sửa (tối đa 5)', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                MaintenancePhotoPicker(files: photos, onChanged: (f) => setSheet(() => photos = f)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          setSheet(() => submitting = true);
                          try {
                            await MaintenanceService.complete(
                              t.id,
                              note: noteController.text.trim(),
                              usedDeviceId: deviceId,
                              usedQuantity: deviceId != null ? quantity : null,
                              photos: photos,
                            );
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            _toast('Đã hoàn thành công việc');
                            _load();
                          } catch (e) {
                            setSheet(() => submitting = false);
                            _toast(e.toString().replaceFirst('Exception: ', ''));
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Xác Nhận Hoàn Thành', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _load(showLoading: false),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                  const SizedBox(height: 12),
                  Center(child: TextButton(onPressed: _load, child: const Text('Thử lại'))),
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Công Việc Sửa Chữa Được Giao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildFilters(),
                    const SizedBox(height: 12),
                    if (_visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Column(children: [
                          const Icon(Icons.assignment_turned_in_outlined, size: 64, color: AppColors.textSecondaryLight),
                          const SizedBox(height: 12),
                          Text(
                            _filter == 'TODO' ? 'Không có việc cần xử lý' : 'Chưa có công việc nào',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text('Chủ trọ sẽ giao việc cho bạn khi có sự cố',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        ]),
                      ),
                    ..._visible.map((t) => MaintenanceTicketCard(
                          ticket: t,
                          showReporter: true,
                          onTap: () => showMaintenanceTicketDetail(context, t),
                          actions: [
                            if (_isTodo(t))
                              ElevatedButton(
                                onPressed: () => _showCompleteSheet(t),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                child: const Text('Xác Nhận Hoàn Thành',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        )),
                  ],
                ),
    );
  }

  Widget _buildFilters() {
    final todo = _tasks.where(_isTodo).length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final entries = <String, String>{
      'TODO': 'Cần xử lý ($todo)',
      'DONE': 'Đã xong ($done)',
      'ALL': 'Tất cả (${_tasks.length})',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: entries.entries.map((e) {
          final active = _filter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.textPrimaryLight)),
              selected: active,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}
