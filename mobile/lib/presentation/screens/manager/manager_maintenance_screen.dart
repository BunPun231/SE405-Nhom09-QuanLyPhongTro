import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ManagerMaintenanceScreen extends StatelessWidget {
  const ManagerMaintenanceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Yêu Cầu Bảo Trì Từ Khách', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            title: const Text('Phòng P205 - Rò rỉ vòi nước', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: const Text('Báo lúc: 30 phút trước | Chưa giao thợ', style: TextStyle(fontSize: 11)),
            trailing: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Giao Thợ', style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }
}
