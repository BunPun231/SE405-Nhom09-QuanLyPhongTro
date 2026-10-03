import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ManagerNotificationsScreen extends StatefulWidget {
  const ManagerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<ManagerNotificationsScreen> createState() => _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState extends State<ManagerNotificationsScreen> {
  final List<Map<String, dynamic>> _sentHistory = [
    {
      'title': 'Thông báo đóng tiền phòng Tháng 10',
      'content': 'Vui lòng thanh toán tiền phòng và điện nước trước ngày 05/10/2026 qua VietQR.',
      'target': 'Tất cả phòng (18/18)',
      'time': '01/10/2026 08:30',
      'channel': 'App Push + Zalo',
    },
    {
      'title': 'Thông báo tạm ngưng cấp nước sinh hoạt',
      'content': 'Sẽ cúp nước từ 13h - 17h ngày 28/09 để súc rửa bồn nước mái.',
      'target': 'Tất cả phòng (18/18)',
      'time': '27/09/2026 15:00',
      'channel': 'App Push',
    },
    {
      'title': 'Nhắc nhở nộp CCCD đăng ký tạm trú',
      'content': 'Các phòng P102, P205 vui lòng bổ sung ảnh CCCD trước thứ 6.',
      'target': 'Phòng P102, P205',
      'time': '15/09/2026 10:15',
      'channel': 'SMS Direct',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showSendNotificationSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text('Gửi Thông Báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Lịch sử tin nhắn & thông báo đã gửi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _sentHistory.length,
              itemBuilder: (context, index) {
                final item = _sentHistory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(item['channel'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item['content'], style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Gửi đến: ${item['target']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                          Text(item['time'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSendNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Gửi Thông Báo Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Tiêu đề thông báo', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Nội dung thông báo', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Đối tượng nhận', border: OutlineInputBorder()),
              value: 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả khách thuê')),
                DropdownMenuItem(value: 'overdue', child: Text('Khách còn nợ tiền trọ')),
                DropdownMenuItem(value: 'p101', child: Text('Phòng P101')),
              ],
              onChanged: (val) {},
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('Phát tin nhắn ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi thông báo đến các khách thuê!')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
