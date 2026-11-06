import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_service.dart';
import '../../../core/services/maintenance_service.dart';

class TechnicianEquipmentScreen extends StatefulWidget {
  const TechnicianEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<TechnicianEquipmentScreen> createState() => _TechnicianEquipmentScreenState();
}

class _TechnicianEquipmentScreenState extends State<TechnicianEquipmentScreen> {
  List<int> _motelIds = []; // khu trọ KTV phụ trách, suy ra từ các phiếu được giao
  int? _selectedMotelId;
  List<DeviceResult> _devices = [];
  String _query = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tasks = await MaintenanceService.listMyTasks(size: 100);
      final ids = tasks.content.map((t) => t.motelId).whereType<int>().toSet().toList()..sort();
      _motelIds = ids;
      if (ids.isNotEmpty) {
        _selectedMotelId = ids.contains(_selectedMotelId) ? _selectedMotelId : ids.first;
        final res = await DeviceService.list(_selectedMotelId!);
        _devices = res.content;
      } else {
        _devices = [];
      }
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _selectMotel(int id) async {
    setState(() {
      _selectedMotelId = id;
      _isLoading = true;
    });
    try {
      final res = await DeviceService.list(id);
      if (mounted) {
        setState(() {
          _devices = res.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<DeviceResult> get _visible {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _devices;
    return _devices.where((d) => d.name.toLowerCase().contains(q) || (d.brand ?? '').toLowerCase().contains(q)).toList();
  }

  void _showLogs(DeviceResult d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scroll) => FutureBuilder<List<DeviceMovementLog>>(
          future: DeviceService.movementLogs(d.motelId, d.id),
          builder: (context, snap) {
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              children: [
                Text(d.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Lịch sử biến động kho', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                if (snap.connectionState != ConnectionState.done)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (snap.hasError)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Không tải được lịch sử', style: TextStyle(color: AppColors.danger))),
                  )
                else if ((snap.data ?? []).isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Chưa có biến động nào', style: TextStyle(color: AppColors.textSecondaryLight))),
                  )
                else
                  ...snap.data!.map((l) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          dense: true,
                          leading: const Icon(Icons.swap_vert_rounded, color: AppColors.primary),
                          title: Text('${l.actionLabel} · SL ${l.quantity}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            [
                              if (l.timestamp != null) DateFormat('dd/MM/yyyy HH:mm').format(l.timestamp!.toLocal()),
                              if ((l.note ?? '').isNotEmpty) l.note!,
                            ].join(' · '),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ListView(children: [
                  const SizedBox(height: 120),
                  Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
                  const SizedBox(height: 12),
                  Center(child: TextButton(onPressed: _load, child: const Text('Thử lại'))),
                ])
              : _motelIds.isEmpty
                  ? ListView(children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
                        child: Column(children: const [
                          Icon(Icons.memory_rounded, size: 64, color: AppColors.textSecondaryLight),
                          SizedBox(height: 12),
                          Text('Chưa có thiết bị để hiển thị', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text(
                            'Danh mục thiết bị sẽ hiện khi bạn được giao việc ở một khu trọ',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                          ),
                        ]),
                      ),
                    ])
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Danh Mục Thiết Bị & Vật Tư', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        if (_motelIds.length > 1) ...[
                          DropdownButtonFormField<int>(
                            value: _selectedMotelId,
                            decoration: const InputDecoration(
                              labelText: 'Khu trọ',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _motelIds.map((id) => DropdownMenuItem(value: id, child: Text('Khu trọ #$id'))).toList(),
                            onChanged: (v) {
                              if (v != null) _selectMotel(v);
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'Tìm theo tên hoặc hãng...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_visible.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                _devices.isEmpty ? 'Khu trọ này chưa có thiết bị' : 'Không tìm thấy thiết bị phù hợp',
                                style: const TextStyle(color: AppColors.textSecondaryLight),
                              ),
                            ),
                          ),
                        ..._visible.map(_buildDeviceCard),
                      ],
                    ),
    );
  }

  Widget _buildDeviceCard(DeviceResult d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showLogs(d),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if ((d.brand ?? '').isNotEmpty)
                      Text(d.brand!, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondaryLight),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat('Tổng', d.totalQuantity, AppColors.primary)),
                const SizedBox(width: 8),
                Expanded(child: _stat('Sẵn có', d.availableQuantity, AppColors.success)),
                const SizedBox(width: 8),
                Expanded(child: _stat('Đang dùng', d.inUseQuantity, AppColors.info)),
                const SizedBox(width: 8),
                Expanded(child: _stat('Đang sửa', d.repairingQuantity, AppColors.warning)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text('$value', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
