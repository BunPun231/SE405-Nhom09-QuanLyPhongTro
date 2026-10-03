import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TenantMaintenanceScreen extends StatefulWidget {
  const TenantMaintenanceScreen({Key? key}) : super(key: key);

  @override
  State<TenantMaintenanceScreen> createState() => _TenantMaintenanceScreenState();
}

class _TenantMaintenanceScreenState extends State<TenantMaintenanceScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  final List<Map<String, String>> _tickets = [
    {
      'title': 'Rò rỉ vòi nước chậu rửa mặt',
      'desc': 'Vòi nước bị rỉ liên tục gây lãng phí',
      'date': '30 phút trước',
      'status': 'Processing',
    },
    {
      'title': 'Bóng đèn tuýp ban công bị nhấp nháy',
      'desc': 'Cần thay bóng đèn mới',
      'date': '2 ngày trước',
      'status': 'Done',
    },
  ];

  void _submitTicket() {
    if (_titleController.text.trim().isEmpty) return;
    setState(() {
      _tickets.insert(0, {
        'title': _titleController.text,
        'desc': _descController.text,
        'date': 'Vừa xong',
        'status': 'Pending',
      });
    });
    _titleController.clear();
    _descController.clear();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã gửi báo cáo sự cố tới Quản lý')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReportModal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Tạo Báo Cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Danh Sách Sự Cố Đã Báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ..._tickets.map((t) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(t['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          _buildStatusChip(t['status']!),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(t['desc']!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 8),
                      Text('Thời gian: ${t['date']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    if (status == 'Done') {
      color = AppColors.success;
      label = 'Đã Hoàn Thành';
    } else if (status == 'Processing') {
      color = AppColors.warning;
      label = 'Đang Xử Lý';
    } else {
      color = AppColors.info;
      label = 'Đã Gửi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showReportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Báo Cáo Sự Cố Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Tên sự cố (VD: Hỏng vòi nước)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Mô tả chi tiết', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitTicket,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Gửi Báo Cáo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
