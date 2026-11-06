import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/contract_service.dart';
import '../../../core/services/maintenance_service.dart';
import '../../widgets/maintenance_widgets.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  const TenantMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<TenantMaintenanceScreen> createState() => _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  List<MaintenanceTicketResult> _tickets = [];
  ContractResult? _contract; // hợp đồng đang hiệu lực -> xác định phòng báo sự cố
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
      final results = await Future.wait([
        MaintenanceService.listMine(),
        ContractService.listMine(),
      ]);
      final page = results[0] as dynamic;
      final contracts = results[1] as List<ContractResult>;
      if (!mounted) return;
      setState(() {
        _tickets = List<MaintenanceTicketResult>.from(page.content);
        _contract = contracts.isNotEmpty ? contracts.first : null;
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

  Future<void> _cancelTicket(MaintenanceTicketResult t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy báo cáo sự cố?'),
        content: Text('Phiếu "${t.categoryLabel}" phòng ${t.roomNumber} sẽ bị hủy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ lại')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy phiếu', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await MaintenanceService.cancel(t.id);
      _toast('Đã hủy báo cáo sự cố');
      _load();
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contract == null
            ? () => _toast('Bạn cần có hợp đồng đang hiệu lực để báo sự cố')
            : () => _showReportModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tạo Báo Cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
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
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('Danh Sách Sự Cố Đã Báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_tickets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(children: const [
                            Icon(Icons.handyman_outlined, size: 64, color: AppColors.textSecondaryLight),
                            SizedBox(height: 12),
                            Text('Chưa có sự cố nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text('Bấm "Tạo Báo Cáo" để gửi sự cố tới chủ trọ',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                          ]),
                        ),
                      ..._tickets.map((t) => MaintenanceTicketCard(
                            ticket: t,
                            onTap: () => showMaintenanceTicketDetail(context, t),
                            actions: [
                              if (t.isOpen)
                                OutlinedButton(
                                  onPressed: () => _cancelTicket(t),
                                  child: const Text('Hủy phiếu'),
                                ),
                            ],
                          )),
                      const SizedBox(height: 80),
                    ],
                  ),
      ),
    );
  }

  void _showReportModal(BuildContext context) {
    final descController = TextEditingController();
    var category = 'ELECTRICITY';
    var priority = 'MEDIUM';
    var photos = <XFile>[];
    var submitting = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => Padding(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Báo Cáo Sự Cố Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Phòng #${_contract!.roomId}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 12),
                MaintenanceErrorBanner(error),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: maintenanceInputDecoration('Loại sự cố'),
                  items: kMaintenanceCategories.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setSheet(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: maintenanceInputDecoration('Mức độ ưu tiên'),
                  items: kMaintenancePriorities.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setSheet(() => priority = v ?? priority),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Ảnh hiện trạng (tối đa 5)', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 8),
                MaintenancePhotoPicker(files: photos, onChanged: (f) => setSheet(() => photos = f)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (descController.text.trim().isEmpty) {
                            setSheet(() => error = 'Vui lòng nhập mô tả sự cố');
                            return;
                          }
                          setSheet(() {
                            submitting = true;
                            error = null;
                          });
                          try {
                            await MaintenanceService.createTicket(
                              roomId: _contract!.roomId,
                              description: descController.text.trim(),
                              category: category,
                              priority: priority,
                              photos: photos,
                            );
                            if (sheetContext.mounted) Navigator.pop(sheetContext);
                            _toast('Đã gửi báo cáo sự cố tới Quản lý');
                            _load();
                          } catch (e) {
                            setSheet(() {
                              submitting = false;
                              error = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gửi Báo Cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
