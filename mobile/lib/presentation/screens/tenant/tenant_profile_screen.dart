import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TenantProfileScreen extends StatelessWidget {
  const TenantProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary,
                child: Text('Q', style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),
              Text('Nguyễn Văn Quyền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Phòng P205 - Khách thuê', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_rounded, color: AppColors.primary),
                title: const Text('Số điện thoại'),
                subtitle: const Text('0987 654 321'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_rounded, color: AppColors.primary),
                title: const Text('Số CCCD'),
                subtitle: const Text('001203009988'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.email_rounded, color: AppColors.primary),
                title: const Text('Email'),
                subtitle: const Text('quyen.nguyen@gmail.com'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
